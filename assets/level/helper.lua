local helper = { }

local rng = love.math.newRandomGenerator(4001)
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

return helper