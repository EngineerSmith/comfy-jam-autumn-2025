local ai = {
  speed = 0.8,
  state = "idle",
  timer = 0,
  wanderCircle = {
    x = 0, y = 0, r = 1.5,
  },
  exclusionCircles = { },
  interaction = { },
  queue = { },
  currentBehaviour = nil,

  scriptMoveQueue = { },
  currentScriptMove = nil,
  completedScriptMoves = { },
  scriptMoveCounter = 0,
}

local logger = require("util.logger")

local behaviours = require("src.world.nest.ai.behaviours")

-- The amount of time the AI is allowed to be idle for, before it tries to do it's own thing
local AI_AT_IDLE = 3.0 -- seconds

local MAX_TRIES_WANDER = 50
local MIN_WANDER_DIST = 0.05

local INTERACT_CHANCE = 0.2 -- 0..1
local RECENCY_TIME = 10.0 -- seconds


ai.addCharacterControl = function(object)
  ai.character = object
end

ai.setWanderArea = function(x, y, r)
  ai.wanderCircle.x = x
  ai.wanderCircle.y = y
  ai.wanderCircle.r = r
end

ai.addExclusionZone = function(x, y, r)
  table.insert(ai.exclusionCircles, {
    x = x, y = y, r = r,
    rSqu = r * r,
  })
end

ai.addInteraction = function(name, x, y, r, interactX, interactY, scriptID)
  if ai.interaction[name] then
    logger.warn("Tried to add existing interaction: "..name)
    return
  end
  ai.addExclusionZone(x, y, r)
  ai.interaction[name] = {
    x = interactX, y = interactY,
    scriptID = scriptID,
    lastVisit = 0,
  }
  logger.info("Added interaction "..name)
end

ai.startBehaviour = function(behaviourID, ...)
  table.insert(ai.queue, 1, {
    type = "behaviour",
    id = behaviourID,
    args = { ... },
  })
end

ai.triggerInteraction = function(name, isPriority)
  local action = {
    type = "interaction",
    name = name,
  }
  if isPriority then
    table.insert(ai.queue, 1, action)
  else
    table.insert(ai.queue, action)
  end
end

ai.moveBy = function(dx, dy)
  if ai.state ~= "script" then
    logger.warn("ai.moveby called while not in 'script' state. State: "..ai.state)
    return -1
  end

  dx = dx or 0
  dy = dy or 0

  local moveID = ai.scriptMoveCounter
  ai.scriptMoveCounter = ai.scriptMoveCounter + 1

  if dx == 0 and dy == 0 then
    ai.completedScriptMove[moveID] = true
    return moveID
  end

  local task = {
    id = moveID,
    dx = dx,
    dy = dy,
  }
  table.insert(ai.scriptMoveQueue, task)
  return moveID
end

ai.isMoveFinished = function(id)
  if id == -1 then
    return true
  end
  return ai.completedScriptMoves[id] == true
end


local isInExclusionZone = function(px, py)
  for _, circle in ipairs(ai.exclusionCircles) do
    local dx, dy = px - circle.x, py - circle.y
    local magSqu = dx * dx + dy * dy
    if magSqu < circle.rSqu then
      return true
    end
  end
  return false
end

local doesPathIntersectExclusion = function(x1, y1, x2, y2)
  for _, circle in ipairs(ai.exclusionCircles) do
    local dx, dy = x2 - x1, y2 - y1
    local magSqu = dx * dx + dy * dy

    local t
    if magSqu == 0 then
      t = 0
    else
      local cx, cy = circle.x - x1, circle.y - y1
      local dot = cx * dx + cy * dy
      t = dot / magSqu
    end
    t = math.min(1.0, math.max(0.0, t))

    local closestX = x1 + t * dx
    local closestY = y1 + t * dy

    local distX = circle.x - closestX
    local distY = circle.y - closestY
    local distSqu = distX * distX + distY * distY

    if distSqu < circle.rSqu then
      return true
    end
  end
  return false
end

ai.getWanderPoint = function()
  assert(ai.character, "Tried to get wander point with no character")
  local startX, startY = ai.character.x, ai.character.y

  local isStuck = isInExclusionZone(startX, startY)

  for _ = 1, MAX_TRIES_WANDER do
    local ang = love.math.random() * 2 * math.pi
    local rad = ai.wanderCircle.r * math.sqrt(love.math.random())
    local x = ai.wanderCircle.x + rad * math.cos(ang)
    local y = ai.wanderCircle.y + rad * math.sin(ang)
    local dx, dy = x - startX, y - startY
    local magSqu = dx * dx + dy * dy
    local isDestinationValid = not isInExclusionZone(x, y)
    -- If we are currently stuck, we only require the destination to be valid
    --  to allow the AI to move out of the zone. Otherwise, check for path intersection.
    local isPathValid = isStuck or not doesPathIntersectExclusion(startX, startY, x, y)
    if magSqu > MIN_WANDER_DIST and isDestinationValid and isPathValid then
      return x, y
    end
  end
  -- fallback
  return startX, startY
end

local calculateInteractionWeight = function(interaction)
  local char = ai.character
  if not char then return math.huge end

  local distSqu = (interaction.x - char.x)^2 + (interaction.y - char.y)^2
  local distance = math.sqrt(distSqu)
  local distanceWeight = 1.0 / (distance + 0.1) -- Closer is better

  local timeSinceVisit = love.timer.getTime() - interaction.lastVisit
  local recencyBonus = 1.0 + (timeSinceVisit / RECENCY_TIME) -- scales up the longer it has been

  return distanceWeight * recencyBonus
end

local getRandomWeightedInteraction = function()
  local availableInteractions = { }
  local totalWeight = 0
  local validCount = 0

  for name, interaction in pairs(ai.interaction) do
    if interaction.scriptID then
      validCount = validCount + 1
      local weight = calculateInteractionWeight(interaction)
      table.insert(availableInteractions, {
        name = name,
        weight = weight,
        lastVisit = interaction.lastVisit,
      })
      totalWeight = totalWeight + weight
    end
  end

  if validCount == 0 then
    return nil -- no valid interactions
  end

  if validCount == 1 then
    local onlyInteraction = availableInteractions[1]
    local timeSinceVisit = love.timer.getTime() - onlyInteraction.lastVisit

    if timeSinceVisit < RECENCY_TIME then
      return nil
    else
      return onlyInteraction.name
    end
  end

  local r = love.math.random() * totalWeight
  for _, item in ipairs(availableInteractions) do
    r = r - item.weight
    if r <= 0 then
      return item.name
    end
  end

  -- fallback
  return availableInteractions[#availableInteractions].name
end

local resetScriptMoveState = function()
  ai.scriptMoveQueue = { }
  ai.currentScriptMove = nil
  ai.completedScriptMoves = { }
  -- ai.scriptMoveCounter = 0 -- if we reset the moveCounter; it could introduce bugs if some how an old script checks
end

ai.finishedScript = function()
  if ai.state ~= "script" then
    return
  end
  ai.state = "idle"
  ai.scriptInstanceID = nil
  ai.character.x, ai.character.y = unpack(ai.target) -- Ensure character is back before it started the script

  resetScriptMoveState()
end

ai.resetState = function()
  ai.interrupt()
  ai.state = "idle"
  ai.timer = 0
  ai.currentBehaviour = nil
  ai.queue = { } -- clear pending queue

  resetScriptMoveState()
end

ai.interrupt = function()
  if ai.state ~= "script" then
    return
  end
  local scriptingEngine = require("src.scripting")
  local status = scriptingEngine.getScriptStatus(ai.scriptInstanceID)
  if status == "finished" then
    ai.finishedScript()
    return
  end

  local success = scriptingEngine.interruptScript(ai.scriptInstanceID)
  if success then
    ai.finishedScript()
  end
end

ai.update = function(dt)
  if not ai.character then
    return -- character not get set; nothing to update
  end
  if ai.state == "idle" then
    ai.timer = ai.timer + dt
    if #ai.queue > 0 then
      local action = table.remove(ai.queue, 1)
      ai.timer = 0
      if action.type == "interaction" and ai.interaction[action.name] then
        local interaction = ai.interaction[action.name]
        interaction.lastVisit = love.timer.getTime()
        ai.target = { interaction.x, interaction.y } -- Reach target even if it means phasing through exclusion zones;; todo path finding?
        ai.scriptID = interaction.scriptID
        ai.state = "interact"
        return
      elseif action.type == "behaviour" then
        ai.currentBehaviour = {
          id = action.id,
          state = behaviours[action.id].initialise(ai, unpack(action.args)),
        }
        ai.state = "behaviour"
        return
      end
    end
    if ai.timer >= AI_AT_IDLE then
      ai.timer = 0
      local consumed = false
      if love.math.random() <= INTERACT_CHANCE then
        local name = getRandomWeightedInteraction()
        if name then
          consumed = true
          local interaction = ai.interaction[name]
          interaction.lastVisit = love.timer.getTime()
          ai.target = { interaction.x, interaction.y }
          ai.scriptID = interaction.scriptID
          ai.state = "interact"
        end
      end
      if not consumed then
        local toX, toY = ai.getWanderPoint()
        ai.target = { toX, toY }
        ai.state = "wander"
      end
    end
  elseif ai.state == "script" then
    local isMoving = false
    if ai.currentScriptMove then
      isMoving = true
      local move = ai.currentScriptMove
      local toX, toY = move.toX, move.toY
      local startX, startY = ai.character.x, ai.character.y
      local dx, dy = toX - startX, toY - startY
      local mag = math.sqrt(dx * dx + dy * dy)
      local speed = ai.speed * dt
      if mag >= speed then
        local normalX, normalY = dx / mag, dy / mag
        ai.character:move(normalX * speed, normalY * speed)
      else
        ai.character.x = toX
        ai.character.y = toY
        ai.completedScriptMoves[move.id] = true
        ai.currentScriptMove = nil
        isMoving = false
      end
    elseif #ai.scriptMoveQueue > 0 then
      local task = table.remove(ai.scriptMoveQueue, 1)
      local toX = ai.character.x + task.dx
      local toY = ai.character.y + task.dy
      ai.currentScriptMove = {
        id = task.id,
        toX = toX,
        toY = toY,
      }
      isMoving = true
    end
    if not isMoving then
      local scriptingEngine = require("src.scripting")
      local status = scriptingEngine.getScriptStatus(ai.scriptInstanceID)
      if status == "finished" then
        ai.finishedScript()
      end
    end
  elseif ai.state == "wander" or ai.state == "interact" then
    local toX, toY = unpack(ai.target)
    if not toX or not toY then
      ai.state = "idle"
      return
    end
    local startX, startY = ai.character.x, ai.character.y
    local dx, dy = toX - startX, toY - startY
    local mag = math.sqrt(dx * dx + dy * dy)
    local speed = ai.speed * dt
    if mag >= speed then
      local normX, normY = dx / mag, dy / mag
      ai.character:move(normX * speed, normY * speed, true)
    else -- Reached wander point
      ai.character.x = toX
      ai.character.y = toY

      if ai.state == "wander" then
        ai.state = "idle"
      elseif ai.state == "interact" and ai.scriptID ~= nil then
        ai.state = "script"
        local scriptingEngine = require("src.scripting")
        local instanceID = scriptingEngine.startScript(ai.scriptID)
        if instanceID then
          ai.scriptInstanceID = instanceID
        else
          ai.state = "idle"
          logger.warn("AI couldn't switch to script state.")
        end
        ai.scriptID = nil
      else -- Assume something went wrong, we don't want to stick in that wrongful state
        ai.state = "idle"
      end
      return
    end
  elseif ai.state == "behaviour" then
    if ai.currentBehaviour and behaviours[ai.currentBehaviour.id] then
      local behaviourLogic = behaviours[ai.currentBehaviour.id]
      local isFinished = not behaviourLogic.update(dt, ai.currentBehaviour.state)

      if isFinished then
        ai.currentBehaviour = nil
        ai.state = "idle"
        ai.timer = AI_AT_IDLE
      end
    else -- fallback
      ai.currentBehaviour = nil
      ai.state = "idle"
    end
  end
end

return ai