local helper = { }

local rng = love.math.newRandomGenerator(4001)
local randomChoice = function(tbl)
  return tbl[rng:random(#tbl)]
end

local randomRange = function(min, max)
  return min + (max - min) * rng:random()
end

local magSqu = function(x1, y1, x2, y2)
  local dx, dy = x1 - x2, y1 - y2
  return dx * dx + dy * dy
end

helper.addModelClump = function(models, min, max, minScale, maxScale, level, x, y, radius, z)
  min, max = min or 2, max or 4
  minScale, maxScale = minScale or 2, maxScale or 4
  radius = radius or 2
  z = z or 0

  local scaleDecimalPlace = 10
  minScale = minScale * scaleDecimalPlace
  maxScale = maxScale * scaleDecimalPlace

  for _ = 1, rng:random(min, max) do
    local modelName = models[rng:random(#models)]
    local angle = rng:random() * 2 * math.pi
    local dist = radius * math.sqrt(rng:random())
    table.insert(helper.mapData.models, {
      model = modelName,
      level = level,
      x = x + (dist * math.cos(angle)),
      y = y + (dist * math.sin(angle)),
      z = z,
      scale = rng:random(minScale, maxScale) / scaleDecimalPlace,
      rz = rng:random() * 2 * math.pi,
    })
  end
end

local grassModels = {
  "model.grass",
  "model.grass.large",
  "model.grass.leafs",
  "model.grass.leafs.large",
}
helper.addGrassClump = function(...)
  return helper.addModelClump(grassModels, 4, 7, 2, 4, ...)
end

local pebbleModels = {
  "model.path.stone.1",
  "model.path.stone.2",
  "model.path.stone.3",
  "model.path.stone.4",
}
helper.addPebbleClump = function(...)
  if not select(4, ...) then
    local varargs = { ... }
    varargs[4] = 3 -- default radius to 3
    return helper.addModelClump(pebbleModels, 2, 3, 1.5, 3, unpack(varargs))
  end
  return helper.addModelClump(pebbleModels, 2, 3, 1.5, 3, ...)
end

helper.addCollectable = function(tag, level, x, y, zone)
  table.insert(helper.mapData.collectables, {
    x = x, y = y,
    level = level,
    tag = tag,
    zone = zone,
  })
end

helper.addLeafLine = function(level, zone, startX, startY, endX, endY, count, tag)
  count = count or 5
  tag = tag or "LEAF"

  local dx, dy = endX - startX, endY - startY

  for i = 1, count do
    local t = (i - 1) / (count - 1)
    local x = startX + dx * t
    local y = startY + dy * t

    helper.addCollectable(tag, level, x, y, zone)
  end
end

helper.addLeafCircle = function(level, zone, centerX, centerY, radius, count, tag)
  count = count or 8
  tag = tag or "LEAF"

  for i = 1, count do
    local angle = (i / count) * 2 * math.pi
    local x = centerX + radius * math.cos(angle)
    local y = centerY + radius * math.sin(angle)

    helper.addCollectable(tag, level, x, y, zone)
  end
end


helper.placePath = function(level, bezierCurve, pathModels, litterModels)
  local T_INCREMENT = 0.002
  local SEGMENT_LENGTH = 1.1
  local SEGMENT_LENGTH_SQU = SEGMENT_LENGTH * SEGMENT_LENGTH

  local PATH_WIDTH = 1.0
  local LITTER_OFFSET = 0.3
  local PATH_Z_POS = 0
  local PATH_Z_JITTER = 0.05
  local LITTER_CHANCE = 0.6
  local LITTER_Z_POS = 0.0
  local LITTER_Z_JITTER = 0.05
  local LITTER_PLACEMENT_RANGE = PATH_WIDTH + LITTER_OFFSET

  local placeSegmentAndLitter = function(t, x, y)
    local nextT = math.min(t + 0.01, 1)
    local nextX, nextY = bezierCurve:evaluate(nextT)

    local tangentX, tangentY = nextX - x, nextY - y
    if tangentX == 0 and tangentY == 0 then
      return
    end
    local rotation = math.atan2(tangentY, tangentX)
    local model = randomChoice(pathModels)
    table.insert(helper.mapData.models, {
      model = type(model) == "table" and model[1] or model,
      x = x, y = y, z = randomRange(PATH_Z_POS - PATH_Z_JITTER, PATH_Z_POS + PATH_Z_JITTER),
      rz = rotation + randomRange(-0.05, 0.05),
      scale = type(model) == "table" and randomRange(model.scaleMin, model.scaleMax) or randomRange(0.8, 1.4),
      level = level,
    })
    -- Litter
    local normalX = -tangentY
    local normalY =  tangentX
    local normalMag = math.sqrt(normalX * normalX + normalY * normalY)
    if normalMag > 0 then
      normalX = normalX / normalMag
      normalY = normalY / normalMag
    else
      return
    end
    -- LITTER RIGHT
    if rng:random() < LITTER_CHANCE then -- 70% chance to place a litter clump
      local litterDist = randomRange(0, 0.4)
      local litterX = x + normalX * (LITTER_PLACEMENT_RANGE + litterDist)
      local litterY = y + normalY * (LITTER_PLACEMENT_RANGE + litterDist)
      table.insert(helper.mapData.models, {
        model = randomChoice(litterModels),
        x = litterX, y = litterY, z = randomRange(LITTER_Z_POS - LITTER_Z_JITTER, LITTER_Z_POS + LITTER_Z_JITTER),
        rz = randomRange(0, 2 * math.pi),
        scale = randomRange(0.9, 1.4),
        level = level,
      })
    end
    -- LITTER LEFT
    if rng:random() < LITTER_CHANCE then
      local litterDist = randomRange(0, 0.4)
      local litterX = x + -normalX * (LITTER_PLACEMENT_RANGE + litterDist)
      local litterY = y + -normalY * (LITTER_PLACEMENT_RANGE + litterDist)
      table.insert(helper.mapData.models, {
        model = randomChoice(litterModels),
        x = litterX, y = litterY, z = randomRange(LITTER_Z_POS - LITTER_Z_JITTER, LITTER_Z_POS + LITTER_Z_JITTER),
        rz = randomRange(0, 2 * math.pi),
        scale = randomRange(0.9, 1.4),
        level = level,
      })
    end
  end

  local currentT = 0
  local lastX, lastY = bezierCurve:evaluate(currentT)
  placeSegmentAndLitter(currentT, lastX, lastY)

  while currentT < 1 do
    currentT = math.min(currentT + T_INCREMENT, 1)
    local x, y = bezierCurve:evaluate(currentT)
    if magSqu(x, y, lastX, lastY) >= SEGMENT_LENGTH_SQU then
      placeSegmentAndLitter(currentT, x, y)
      lastX, lastY = x, y
    end
    if currentT == 1 and magSqu(x, y, lastX, lastY) > 0.1 then
      placeSegmentAndLitter(currentT, x, y)
    end
  end
end

local dirtPathModels = {
  "model.path.dirt.1",
  "model.path.dirt.2",
  { "model.path.dirt.3", scaleMin = 1.4, scaleMax = 2.8 },
}
local dirtPathLitterModels = {
  "model.path.litter.dirt.1",
  "model.path.litter.dirt.2",
  "model.path.litter.dirt.3",
  "model.path.litter.dirt.4",
}
helper.placeDirtPath = function(level, bezierCurve)
  return helper.placePath(level, bezierCurve, dirtPathModels, dirtPathLitterModels)
end

return helper