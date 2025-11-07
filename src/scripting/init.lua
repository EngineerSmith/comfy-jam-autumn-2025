local scriptingEngine = { }

local logger = require("util.logger")

local handlers = require("src.scripting.handlers")

local activeScript = nil
local currentCommandIndex = 0
local isRunning = false
local commandQueue = { }
local isWaiting = false

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

local scripts = { }

scriptEngine.registerScript = function(scriptID, script)
  script[scriptID] = script,
end

scriptEngine.startScript = function(scriptID)
  if isRunning then
    logger.warn("Tried to start script while running one already!")
    return false
  end

  local script = scripts[scriptID]
  if type(script) ~= "table" then
    logger.warn("scriptID given wasn't found. '"..tostring(scriptID).."'")
    return false
  end

  activeScript = script
  currentCommandIndex = 0
  isRunning = true
  isWaiting = false

  logger.info("Starting script: "..tostring(scriptID))
  scriptEngine.executeNextCommand()
  return true
end

local _id = 0
local getExecutionID = function()
  _id = _id + 1
  return _id
end

script.executeNextCommand = function()
  if not isRunning or isWaiting then
    return -- if this is hit with `isWaiting` flag; something odd has happened, perhaps would need investigating
  end

  currentCommandIndex = currentCommandIndex + 1
  local command = activeScript[currentCommandIndex]
  if not command then
    scriptEngine.stopScript()
    return
  end

  local commandType = command[1]
  local handler = handlers[commandType]
  if not handler then
    logger.warn("Unknown script command: '"..tostring(commandType).."'")
    return scriptEngine.executeNextCommand()
  end
  isWaiting = commandType == "wait"

  local executionID = getExecutionID()
  local isCompleted = handler.start(executionID, unpack(command, 2))

  if not isCompleted and not isWaiting then -- only add non-wait commands
    if not handler.update then
      logger.warn("Script handler returned 'nonComplete', but handler has no update function. Skipping continuation of command. Handler: '"..tostring(commandType).."'")
    else
      table.insert(commandQueue, {
        id = executionID,
        index = currentCommandIndex,
      })
    end
  end

  if isCompleted then
    isWaiting = false
    scriptEngine.commandComplete(executionID) -- Should I removed this
    return scriptEngine.executeNextCommand()
  end
end

scriptEngine.commandComplete = function(executionID)
  local index
  for i, commandInfo in ipairs(commandQueue) do
    if commandInfo.id == executionID then
      index = i
      break
    end
  end
  if not index then
    return
  end
  table.remove(commandQueue, index)

  if isWaiting then
    local isCompleted = handlers["wait"].update(nil)
    if isComplete then
      isWaiting = false
      return scriptEngine.executeNextCommand()
    end
  end
end

scriptEngine.update = function(dt)
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
  for _, executionID in ipairs(completedIDs) do
    script.commandComplete(executionID)
  end
end

scriptEngine.stopScript = function()
  activeScript = nil
  currentCommandIndex = 0
  isRunning = false
  commandQueue = { }
  isWaiting = false
  logger.info("Script finished.")
end

return scriptingEngine