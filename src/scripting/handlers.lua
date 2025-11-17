local handlers = { }

local logger = require("util.logger")
local audioManager = require("util.audioManager")

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
  player.isInputBlocked_cutscene = true
  return true
end

handlers["unlock"] = function(_)
  local player = require("src.player")
  player.isInputBlocked_cutscene = false
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

    if not character:move(moveX, moveY, true) then
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

handlers["characterFace"] = function(_, characterName, direction)
  local world = require("src.world")
  local character = world.characters[characterName]
  if not character then
    logger.warn("Couldn't find character["..tostring(characterName).."] to change facing direction using script.")
    return true -- failed, but skip
  end
  local nx, ny = 0, 0
  if direction == "north" then
    ny = 1
  elseif direction == "south" then
    ny = -1
  elseif direction == "west" then
    nx = 1
  elseif direction == "east" then
    nx = -1
  end
  character:faceDirection(nx, ny)
  return true
end

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

handlers["moveAI"] = {
  start = function(executionID, dx, dy)
    if dx == 0 and dy == 0 then
      return true
    end
    local ai = require("src.world.nest.ai")
    local moveID = ai.moveBy(dx, dy)
    if moveID == -1 then
      logger.warn("Received -1 from ai.moveBy in script")
      return true
    end
    if ai.isMoveFinished(moveID) then
      return true
    end
    memory[executionID] = moveID
    return false
  end,
  update = function(executionID, _, _, _)
    local moveID = memory[executionID]
    local ai = require("src.world.nest.ai")
    if ai.isMoveFinished(moveID) then
      memory[executionID] = nil -- clear memory
      return true
    end
    return false
  end,
}

handlers["aiState"] = function(_, newState)
  local ai = require("src.world.nest.ai")
  if not ai.character then
    logger.warn("AI had no character")
    return true
  end
  ai.character:setState(newState)
  return true
end

handlers["if.nest.bed.level.0"] = function()
  local nest = require("src.world.nest")
  return nest.bedLevel == 0
end

handlers["if.nest.bed.level.1"] = function()
  local nest = require("src.world.nest")
  return nest.bedLevel == 1
end


handlers["playAudio"] = function(_, assetKey, volumeMod)
  audioManager.play(assetKey, volumeMod)
  return true
end

handlers["aiFootstep"] = function()
  local ai = require("src.world.nest.ai")
  local maxRadius = ai.wanderCircle.r
  local minRadius = -maxRadius
  local t = (ai.character.y - minRadius) / (maxRadius - minRadius)
  local volumeMod = math.max(0.1, t)
  audioManager.play("audio.fx.footstep.grass", volumeMod)
  return true
end

handlers["setCutsceneCamera"] = function(_, x, y, z, lookAtX, lookAtY, lookAtZ)
  local scene = require("scenes.game")
  local camera = scene.cutsceneCamera
  if x == "player" then -- Grab player's current camera position to use for smooth cutscene transition
    local player = require("src.player")
          x,       y,       z = unpack(player.camera.position)
    lookAtX, lookAtY, lookAtZ = unpack(player.camera.target)
  elseif lookAtX == "player" then
    local player = require("src.player")
    lookAtX, lookAtY, lookAtZ = unpack(player.camera.position)
  end
  camera:lookAt(x, y, z, lookAtX, lookAtY, lookAtZ)
  return true 
end

handlers["lerpCameraTo"] = {
  start = function(executionID, x, y, z, lookAtX, lookAtY, lookAtZ, seconds)
    local g3d = require("libs.g3d")
    local camera = g3d.camera.current()

    if x == "player" then
      seconds = y
      local player = require("src.player")
            x,       y,       z = unpack(player.camera.position)
      lookAtX, lookAtY, lookAtZ = unpack(player.camera.target)
    end

    if seconds == 0 then
      camera:lookAt(x, y, z, lookAtX, lookAtY, lookAtZ)
      return true
    end

    memory[executionID] = false
    local state = { }
    state[1], state[2], state[3] = unpack(camera.position)
    state[4], state[5], state[6] = unpack(camera.target)
    local flux = require("libs.flux")
    flux.to(state, seconds, { x or state[1], y or state[2], z or state[3], lookAtX or state[4], lookAtY or state[5], lookAtZ or state[6] })
      :onupdate(function()
        camera:lookAt(unpack(state, 1, 6))
      end)
      :oncomplete(function()
        memory[executionID] = true
      end)
      :ease("linear")
    return false
  end,
  update = function(executionID, _, _, _, _, _, _, _, _)
    local isComplete = memory[executionID]
    if isComplete == true then
      memory[executionID] = nil
      return true
    end
    return false
  end,
}

handlers["switchCamera"] = function(_, cameraTo)
  if cameraTo == "cutscene" then
    local scene = require("scenes.game")
    scene.cutsceneCamera:setCurrent()
  elseif cameraTo == "player" then
    local player = require("src.player")
    player.camera:setCurrent()
  end
  return true
end

handlers["createNamedCollider"] = function(_, levelName, name, shape, ...)
  if shape == "circle" then
    local x, y, radius, tag = ...
    tag = tag or "WALL"
    local world = require("src.world")
    local level = world.levels[levelName]
    if not level then
      error("You misspelt the level name: "..tostring(levelName))
    end
    local slick = require("libs.slick")
    local slickHelper = require("util.slickHelper")
    local shape = slick.newCircleShape(0, 0, radius, nil, slickHelper.tags[tag])
    level:add(name, x, y, shape)
  else
    error("unsupported collider, you forgot to add idiot")
  end
  return true
end

handlers["removeNamedCollider"] = function(_, levelName, name)
  local world = require("src.world")
  local level = world.levels[levelName]
  if not level then
    error("You misspelt the level name: "..tostring(levelName))
  end
  if level:isInLevel(name) then
    level:remove(name)
  end
  return true
end

handlers["lerpProp"] = {
  start = function(executionID, propID, toX, toY, toZ, toRX, toRY, toRZ, lerpDuration)
    local world = require("src.world")
    local prop = world.specialProps[propID]
    if not prop then
      logger.warn("Couldn't find prop["..tostring(propID).."] when trying to start lerpProp. Check spelling.")
      return true
    end
    local x, y, z = prop:getPosition()
    local rx, ry, rz = prop:getRotation()

    local targetState = {
      x = toX or x, y = toY or y, z = toZ or z,
      rx = toRX or rx, ry = toRY or ry, rz = toRZ or rz,
    }

    local tween = require("libs.flux").to(prop, lerpDuration or 0.5, targetState)
      :ease("quadout")
      :onupdate(function()
        prop:updateRotation()
      end)
      :oncomplete(function()
        memory[executionID].finished = true
      end)
    memory[executionID] = {
      tween = tween,
      finished = false,
    }
    return false
  end,
  update = function(executionID, _, _, _, _, _, _, _)
    local mem = memory[executionID]
    if mem.finished then
      memory[executionID] = nil
      return true
    end
    return false
  end,
}

handlers["removePropCollider"] = function(_, propID)
  local world = require("src.world")
  local prop = world.specialProps[propID]
  if not prop then
    logger.warn("Couldn't find prop["..tostring(propID).."] when trying to removePropCollider. Check spelling.")
    return true
  end
  if prop.collider then
    prop.collider:remove()
    prop.collider = nil
  end
  return true
end

handlers["addTransition"] = function(_, x, y, width, height, edgeMap)
  local world = require("src.world")
  world.addTransition(x, y, width, height, edgeMap)
  return true
end

handlers["firstTimeEnterZone1"] = function()
  local player = require("src.player")
  if not player.flags["zone1"] then
    player.flags["zone1"] = true
    return true
  end
  return false
end

handlers["finishedNest"] = function()
  local nest = require("src.world.nest")
  return nest.unlockBall and nest.bedLevel >= 1
end

handlers["unlockPumpkinBall"] = function()
  local nest = require("src.world.nest")
  nest.unlockBall()
  return true
end

handlers["startBehaviour"] = function(_, behaviour)
  local ai = require("src.world.nest.ai")
  if behaviour == "play_ball" then
    local nest = require("src.world.nest")
    ai.startBehaviour("play_ball", nest.ball)
    ai.triggerScript("ai.alert", true)
  end
  return true
end

handlers["playCredits"] = {
  start = function(executionID)
    local game = require("scenes.game")
    game.playCredits(function()
      memory[executionID] = true
    end)
    memory[executionID] = false
    return false
  end,
  update = function(executionID, _)
    local mem = memory[executionID]
    if mem then
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