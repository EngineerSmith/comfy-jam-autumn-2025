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
}

local behaviours = require("src.world.nest.ai.behaviours")

-- The amount of time the AI is allowed to be idle for, before it tries to do it's own thing
local AI_AT_IDLE = 3.0 -- seconds

local MAX_TRIES_WANDER = 50
local MIN_WANDER_DIST = 0.05

local INTERACT_CHANCE = 0.3 -- 0..1
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
  ai.addExclusionZone(x, y, r)
  ai.interaction[name] = {
    x = interactX, y = interactY,
    scriptID = scriptID,
    lastVisit = 0,
  }
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

  for _ = 1, MAX_TRIES_WANDER do
    local ang = love.math.random() * 2 * math.pi
    local rad = ai.wanderCircle.r * math.sqrt(love.math.random())
    local x = ai.wanderCircle.x + rad * math.cos(ang)
    local y = ai.wanderCircle.y + rad * math.sin(ang)
    local dx, dy = x - startX, y - startY
    local magSqu = dx * dx + dy * dy
    if magSqu > MIN_WANDER_DIST and not isInExclusionZone(x, y) and not doesPathIntersectExclusion(startX, startY, x, y) then
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

  for name, interaction in pairs(ai.interaction) do
    if interaction.scriptID then
      local weight = calculateInteractionWeight(interaction)
      table.insert(availableInteractions, {
        name = name,
        weight = weight,
      })
      totalWeight = totalWeight + weight
    end
  end

  if totalWeight == 0 then
    return nil -- no valid interactions
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

ai.finishedScript = function()
  if ai.state ~= "script" then
    return
  end
  ai.state = "idle"
  ai.scriptInstanceID = nil
  ai.character.x, ai.character.y = unpack(ai.target) -- Ensure character is back before it started the script
end

ai.resetState = function()
  ai.interrupt()
  ai.state = "idle"
  ai.timer = 0
  ai.currentBehaviour = nil
  ai.queue = { } -- clear pending queue
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
        ai.target = { interaction.x, interaction.y } -- Reach target even if it means phasing through exclusion zones;; todo path finding?
        ai.scriptID = interaction.scriptID
        ai.state = "interact"
        interaction.lastVisit = love.timer.getTime()
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
    local scriptingEngine = require("src.scripting")
    local status = scriptingEngine.getScriptStatus(ai.scriptInstanceID)
    if status == "finished" then
      ai.finishedScript()
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
        -- Call startScript here
        local scriptingEngine = require("src.scripting")
        local instanceID = scriptingEngine.startScript(ai.scriptID)
        if instanceID then
          ai.state = "script"
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