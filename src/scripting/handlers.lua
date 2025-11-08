local handlers = { }

local logger = require("util.logger")

local memory = { }
-- Use memory by `memory[executionID] = { }` to have information between functions/steps.
-- Remember to clear it when the command finishes.


-- handlers has two fields, or just a function; which defaults to a `start` function
-- `start` and `update`: both functions
-- `start(executionID, ...)` arguments of the command is passed in.
-- `update(executionID, dt, ...)` arguments of the command is passed in.
-- there must be a `start` function,`update` is optional, but it means that `start` always declares the handler as complete
-- `start`, and `update` return one value, `isComplete`


handlers["lock"] = function(_)
  local player = require("src.player")
  player.isInputBlocked = true
  return true
end

handlers["unlock"] = function(_)
  local player = require("src.player")
  player.isInputBlocked = false
  return true
end

handlers["changeStage"] = function(_, toStage)
  local world = require("src.world")
  world.setStage(toStage)
  return true
end

handlers["moveTo"] = {
  start = function(_, characterName, toX, toY)
    local world = require("src.world")
    local character = world.characters[characterName]
    if not character then
      logger.warn("Couldn't find character["..tostring(characterName).."] to move using script.")
      return true -- failed, but skip
    end
    if not character:canMoveTo(toX, toY) then
      logger.warn("Couldn't find a path or destination is blocked for character["..tostring(characterName).."] to: "..("(%.2f, %.2f)"):format(toX, toY))
      return true
    end
    return false -- requires update time steps
  end,
  update = function(_, dt, characterName, toX, toY)
    local world = require("src.world")
    local character = world.characters[characterName]
    if not character then
      return true -- guard against if the character disappears mid-movement
    end

    local cX, cY = character.x, character.y
    local speed = character.speed * dt

    local dx, dy = toX - cX, toY - cY
    local mag = math.sqrt(dx * dx + dy * dy)

    if mag <= speed then
      character:teleport(toX, toY)
      return true
    end

    local dirX = dx / mag
    local dirY = dy / mag

    local moveX = dirX * speed
    local moveY = dirY * speed

    if not character:move(moveX, moveY) then
      -- Movement failed, e.g. hit a wall
      logger.warn("Character["..tostring(characterName).."] failed to move towards destination. Ending command.")
      return true
    end

    return false -- requires additional steps
  end
}

handlers["moveBy"] = {
  start = function(executionID, characterName, deltaX, deltaY)
    local world = require("src.world")
    local character = world.characters[characterName]
    if not character then
      logger.warn("Couldn't find character["..tostring(characterName).."] to glide using script.")
      return true -- failed, but skip
    end

    local cX, cY = character.x, character.y
    local toX, toY = cX + deltaX, cY + deltaY

    if not character:canMoveTo(toX, toY) then
      logger.warn("Couldn't find a path or destination is blocked for character["..tostring(characterName).."] to: "..("(%.2f, %.2f)"):format(toX, toY))
      return true
    end

    memory[executionID] = {
      toX = toX, toY = toY,
    }
    return false -- requires update time steps
  end,
  update = function(executionID, dt, characterName, _, _)
    local mem = memory[executionID]
    local toX, toY = mem.toX, mem.toY

    local isCompleted = handlers["moveTo"].update(executionID, dt, characterName, toX, toY)
    if isCompleted then
      memory[executionID] = nil
      return true
    end
    return false -- requires additional steps
  end,
}

handlers["glideTo"] = {
  start = function(_, characterName, _, _)
    local world = require("src.world")
    local character = world.characters[characterName]
    if not character then
      logger.warn("Couldn't find character["..tostring(characterName).."] to glide using script.")
      return true -- failed, but skip
    end
    return false -- requires update time steps
  end,
  update = function(_, dt, characterName, toX, toY)
    local world = require("src.world")
    local character = world.characters[characterName]
    if not character then
      return true-- guard against if the character disappears mid-movement
    end

    local cX, cY = character.x, character.y
    local speed = character.speed * dt

    local dx, dy = toX - cX, toY - cY
    local mag = math.sqrt(dx * dx + dy * dy)
    if mag <= speed then
      character:teleport(toX, toY)
      return true -- success
    end
    
    local dirX = dx / mag
    local dirY = dy / mag

    local moveX = dirX * speed
    local moveY = dirY * speed

    character:faceDirection(moveX, moveY)
    character:teleport(cX + moveX, cY + moveY)
    return false -- requires additional steps
  end,
}

handlers["glideBy"] = {
  start = function(executionID, characterName, deltaX, deltaY)
    local world = require("src.world")
    local character = world.characters[characterName]
    if not character then
      logger.warn("Couldn't find character["..tostring(characterName).."] to glide using script.")
      return true -- failed, but skip
    end

    local cX, cY = character.x, character.y
    local toX, toY = cX + deltaX, cY + deltaY

    memory[executionID] = {
      toX = toX, toY = toY,
    }
    return false -- requires update time steps
  end,
  update = function(executionID, dt, characterName, _, _)
    local mem = memory[executionID]
    local toX, toY = mem.toX, mem.toY

    local isCompleted = handlers["glideTo"].update(executionID, dt, characterName, toX, toY)
    if isCompleted then
      memory[executionID] = nil
      return true
    end
    return false -- requires additional steps
  end
}

handlers["transition"] = {
  start = function(executionID, transitionType, time)
    local transition = require("src.transition")
    if transitionType == "clear" then -- Clean up left over transition, not needed, but might save a couple cycles
      transition.clearFront()
      return true
    end
    local id = transition.start(transitionType, time)
    memory[executionID] = id
    return false
  end,
  update = function(executionID, _, _, _)
    local transition = require("src.transition")
    local id = memory[executionID]
    if transition.hasFinished(id) then
      memory[executionID] = nil
      return true
    end
    return false
  end,
}

--- handler validation
local keysToRemove = { }
for key, handler in pairs(handlers) do
  if type(handler) == "table" then
    local updateType = type(handler.update)
    if updateType ~= "function" and updateType ~= "nil" then
      logger.warn("Script handler found update callback that wasn't function or nil. Removing: '"..tostring(key).."'")
      table.insert(keysToRemove, key)
    else
      if type(handler.start) ~= "function" then
        if updateType ~= "function" then
          logger.warn("Script handler found without start callback. Removing: '"..tostring(key).."'")
          table.insert(keysToRemove, key)
        else
          handler.start = function(executionID, ...)
            return handler.update(executionID, 0, ...) -- Pass dt as 0,
          end
        end
      end
    end
  elseif type(handler) == "function" then
    handlers[key] = {
      start = handler,
    }
  else
    logger.warn("Script handler found with non-table value. Removing: "..tostring(key).."'")
    table.insert(keysToRemove, key)
  end
end
for _, key in ipairs(keysToRemove) do
  handlers[key] = nil
end

return handlers