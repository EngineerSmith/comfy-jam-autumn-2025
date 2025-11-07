local scriptingEngine = { }

local logger = require("util.logger")

local handlers = require("src.scripting.handlers")

local scripts = { }
local scriptQueue = { }
local sleepTimers = { }

local currentExecutionID = nil
local activeScript = nil
local currentCommandIndex = 0
local isRunning = false
local commandQueue = { }
local isWaiting = false
local blockingCommandID = nil

handlers["wait"] = {
  update = function(_, _)
    if #commandQueue == 0 then
      return true
    end
    return false
  end
}
handlers["wait"].start = function(_)
  return handlers["wait"].update(_, nil)
end

handlers["sleep"] = {
  start = function(executionID, duration)
    if type(duration) == "number" and duration > 0 then
      sleepTimers[executionID] = duration
    end
    return duration and duration <= 0
  end,
  update = function(executionID, dt, duration)
    local remaining = sleepTimers[executionID]

    if not remaining or remaining <= 0 then
      sleepTimers[executionID] = nil
      return true
    end

    remaining = remaining - dt
    sleepTimers[executionID] = remaining

    if remaining <= 0 then
      sleepTimers[executionID] = nil
      return true
    end
    return false
  end,
}


scriptingEngine.registerScript = function(scriptID, script)
  -- Ensure default, boolean values
  script.isMandatory = script.isMandatory == true
  script.multipleQueued = script.multipleQueued == true

  scripts[scriptID] = script
end

scriptingEngine.isInQueue = function(scriptID)
  for _, id in ipairs(scriptQueue) do
    if id == scriptID then
      return true
    end
  end
  return false
end

scriptingEngine.startScript = function(scriptID)
  if currentExecutionID == scriptID then
    logger.warn("Mandatory script '"..tostring(scriptID).."' is currently running.")
    return false, "running"
  end

  local script = scripts[scriptID]
  if type(script) ~= "table" then
    if not scriptID:match("^event%.") then
      logger.warn("scriptID given wasn't found. '"..tostring(scriptID).."'")
    end
    return false, "unknown"
  end

  local isMandatory = script.isMandatory

  if isRunning then
    if isMandatory then
      local multipleQueued = script.multipleQueued
      if multipleQueued or not scriptingEngine.isInQueue(scriptID) then
        table.insert(scriptQueue, scriptID)
        logger.info("Mandatory script '"..tostring(scriptID).."' queued.")
        return true, "queued"
      else
        logger.warn("Mandatory script '"..tostring(scriptID).."' tried to be queued, but is already in the queue.")
        return false, "alreadyQueued"
      end
    else
      logger.warn("Tried to start script while running one already!")
      return false, "busy"
    end
  end

  currentExecutionID = scriptID
  activeScript = script
  currentCommandIndex = 0
  isRunning = true
  isWaiting = false

  logger.info("Starting script: "..tostring(scriptID))
  scriptingEngine.executeNextCommand()
  return true, "running"
end

local _id = 0
local getExecutionID = function()
  _id = _id + 1
  return _id
end

-- The flow of this function is simple
-- It will execute the script, until it reaches the end of the script, or a blocking command
scriptingEngine.executeNextCommand = function()
  if not isRunning or isWaiting then
    return -- if this is hit with `isWaiting` flag; something odd has happened, perhaps would need investigating
  end

  currentCommandIndex = currentCommandIndex + 1
  local command = activeScript[currentCommandIndex]
  if not command then
    if #commandQueue > 0 then
      logger.info("Script reached end, initiating implicit wait for "..#commandQueue.." background commands.")
      isWaiting = true
      blockingCommandID = getExecutionID()
    else
      scriptingEngine.stopScript()
      return
    end
  end

  local commandType = command[1]
  local handler = handlers[commandType]
  if not handler then
    logger.warn("Unknown script command: '"..tostring(commandType).."'")
    scriptingEngine.executeNextCommand()
    return
  end

  local executionID = getExecutionID()
  local isCompleted = handler.start(executionID, unpack(command, 2))

  if isCompleted then
    scriptingEngine.commandComplete(executionID)
    -- Command finished instantly, but we call commandComplete() for **architectural consistency**. 
    -- This ensures all commands pass through the completion path, simplifying future enhancements (e.g., global cleanup, logging).
    scriptingEngine.executeNextCommand()
    return
  else
    local isBlocking = commandType == "wait" or commandType == "sleep"
    if isBlocking then
      isWaiting = true
      blockingCommandID = executionID
      return
    else
      if not handler.update then
        logger.warn("Script handler returned 'nonComplete', but handler has no update function. Skipping continuation of command. Handler: '"..tostring(commandType).."'")
      else
        table.insert(commandQueue, {
          id = executionID,
          index = currentCommandIndex,
        })

        scriptingEngine.executeNextCommand()
        return
      end
    end
  end
end

scriptingEngine.commandComplete = function(executionID)
  local index
  for i, commandInfo in ipairs(commandQueue) do
    if commandInfo.id == executionID then
      index = i
      break
    end
  end
  if index then
    table.remove(commandQueue, index)
  end

  -- If the script is currently blocked by 'wait', check if we can proceed.
  if isWaiting and blockingCommandID and activeScript then
    local isImplicitWait = not activeScript[currentCommandIndex]
    local isExplicitWait = activeScript[currentCommandIndex] and activeScript[currentCommandIndex][1] == "wait"

    if isImplicitWait or isExplicitWait then
      local isCompleted = handlers["wait"].update(blockingCommandID, nil) -- pass nil for dt
      if isCompleted then
        blockingCommandID = nil
        isWaiting = false

        if isImplicitWait then
          scriptingEngine.stopScript()
          return
        end
        scriptingEngine.executeNextCommand()
        return
      end
    end
  end
end

scriptingEngine.update = function(dt)
  if not isRunning then
    return
  end

  local completedIDs = { }
  for _, commandInfo in ipairs(commandQueue) do
    local command = activeScript[commandInfo.index]
    local commandType = command[1]
    local handler = handlers[commandType]

    local executionID = commandInfo.id
    local isCompleted = handler.update(executionID, dt, unpack(command, 2))

    if isCompleted then
      table.insert(completedIDs, executionID)
    end
  end

  local sleepCompletedThisFrame = false

  if isWaiting and blockingCommandID then
    local command = activeScript[currentCommandIndex]
    local commandType = command[1]
    if commandType == "sleep" then
      local isCompleted = handlers[commandType].update(blockingCommandID, dt, unpack(command, 2))
      if isCompleted then
        blockingCommandID = nil
        isWaiting = false
        sleepCompletedThisFrame = true
      end
    end
  end

  for _, executionID in ipairs(completedIDs) do
    scriptingEngine.commandComplete(executionID)
  end

  if sleepCompletedThisFrame and activeScript then
    -- Sleep is deferred to make sure commandQueue isn't added to until all updates have finished for this frame
    scriptingEngine.executeNextCommand()
  end
end

scriptingEngine.stopScript = function()
  if not isRunning then
    return
  end
  logger.info("Script finished: '"..tostring(currentExecutionID).."'")

  currentExecutionID = nil
  activeScript = nil
  currentCommandIndex = 0
  isRunning = false
  commandQueue = { }
  isWaiting = false
  blockingCommandID = nil

  if #scriptQueue > 0 then
    local nextScriptID = table.remove(scriptQueue, 1)
    logger.info("Starting next script from queue: '"..tostring(nextScriptID).."'")
    scriptingEngine.startScript(nextScriptID)
  end
end

return scriptingEngine