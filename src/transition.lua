local transition = {
  queue = { },
  nextID = 1,
}

local parseTransitionType = function(transitionType)
  local base, direction = transitionType:match("([^%.]+)%.([^%.]+)$")
  return base, direction:lower()
end

-- Returns clamped progress time (0.0 to 1.0) for 'out' transitions.
local getNormalizedTime = function(self)
  return math.max(0.0, math.min(1.0, self.time / self.duration))
end

-- Returns inverted clamped progress time (1.0 to 0.0) for 'in' transitions.
local getNormalizedTimeInv = function(self)
  return 1 - getNormalizedTime(self)
end

transition.start = function(transitionType, duration)
  transition.clearFront()

  local baseType, direction = parseTransitionType(transitionType)

  local instance = {
    id = transition.nextID,
    type = baseType,
    getNormalizedTime = direction == "out" and getNormalizedTime or getNormalizedTimeInv,
    duration = duration,
    time = 0,
    finished = false,
  }
  table.insert(transition.queue, instance)

  transition.nextID = transition.nextID + 1
  return instance.id
end

transition.update = function(dt)
  local queueCount = #transition.queue
  if queueCount == 0 then
    return -- nothing to update
  end

  local front = transition.queue[1]
  if front.finished then
    return -- no longer need to update
  end

  front.time = math.min(front.time + dt, front.duration)
  if front.time == front.duration then
    front.finished = true
    if queueCount ~= 1 then -- only remove if there is a transition waiting
      transition.clearFront()
    end
  end
end

transition.clearFront = function()
  if #transition.queue > 0 then
    if transition.queue[1].finished then
      table.remove(transition.queue, 1)
    end
  end
end

transition.hasFinished = function(id)
  if #transition.queue == 0 then
    return transition.nextID > id
  end
  for _, instance in ipairs(transition.queue) do
    if instance.id == id then
      return instance.finished
    elseif instance.id > id then
      return true
    end
  end

  -- Shouldn't reach this point, but we should assume it has finished if it wasn't in the queue
  return true
end

local lg = love.graphics
local transitionStyles = {
  ["CircularWipe"] = function(t)
    lg.setColor(0, 0, 0)
    local width, height = lg.getDimensions()
    local halfWidth, halfHeight = width / 2, height / 2
    local radius = math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight)
    lg.circle("fill", halfWidth, halfHeight, radius * t)
  end,
}

transition.draw = function()
  local front = transition.queue[1]
  if not front then
    return
  end

  local t = front:getNormalizedTime()
  lg.push("all")
  transitionStyles[front.type](t)
  lg.pop()
end

return transition