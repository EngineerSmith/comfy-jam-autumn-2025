local mapData = {
  levels = {
    ["nest.ground"] = { x = -100, y = -100, z = 0, width = 200, height = 200 },
  },
  transitions = {

  },
  models = {
    --- Nest
    { model = "model.surface.1", texture = "texture.prototype.2", level = "nest.ground", x = 0, y = 0, z = -.1 },
    {
      model = "model.flower_pot.nest", level = "nest.ground", x = 0, y = 0, z = -.05, scale = 25,
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.295, segments = 8, rotation = math.rad(22.5), tag = "POT" },
    },
    {
      model = "model.flower_pot.small", level = "nest.ground", x = 11, y = 0, z = 0, scale = 25,
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, rotation = math.rad(90), tag = "POT" },
    },
    {
      model = "model.flower_pot.small",  level = "nest.ground", x = -9, y = 1, z = 0, scale = 25, ry = math.rad(-90), rz = math.rad(30),
      collider = {
        levels = { "nest.ground" }, shape = "multi", tag = "POT",
        { shape = "rectangle", x = -0.2,  y = -0.1,  width = 0.2, height = 0.2,  },
        { shape = "rectangle", x = -0.27, y = -0.15, width = 0.1, height = 0.05, },
        { shape = "rectangle", x = -0.27, y =  0.10, width = 0.1, height = 0.05, },
      }
    },
    {
      model = "model.rock.large.1", level = "nest.ground", x = 0, y = -25, z = -0.14, scale = 25, rz = math.rad(43.5), noScaleZ = true,
      collider = {
        levels = { "nest.ground" }, shape = "multi", tag = "ROCK",
        { shape = "circle", x =  0,   y = -0.13, radius = 0.38 },
        { shape = "circle", x = -0.2, y =  0.35, radius = 0.15 },
      }
    },
  },
  colliders = {
    -- Nest
    { levels = { "nest.ground" }, shape = "rectangle", x = -30, y = -22, width = 60, height = 3, tag = "WALL" }, -- South wall
  },
  collectables = {

  },
  signposts = {
    { level = "nest.ground", x = 0, y = -7.4, z = 4, content = "Press [button.interact] to enter Nest", radius = 3.5, rz = math.rad(0) },
    -- { level = "nest.ground", x = 0, y = -10, content = "Hello World!", radius = 5, rz = math.rad(0) },
  },
  characters = {
    ["Hedgehog.Player"] = {
      file = "assets/characters/hedgehog/init.lua",
      level = "nest.ground",
      x = 0, y = -10,
    }
  },
  playerCharacter = "Hedgehog.Player",
}


local rng = love.math.newRandomGenerator(4001)
local addModelClump = function(models, min, max, minScale, maxScale, level, x, y, radius, z)
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
    table.insert(mapData.models, {
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
local addGrassClump = function(...)
  return addModelClump(grassModels, 4, 7, 2, 4, ...)
end

local pebbleModels = {
  "model.path.stone.1",
  "model.path.stone.2",
  "model.path.stone.3",
  "model.path.stone.4",
}
local addPebbleClump = function(...)
  if not select(4, ...) then
    local varargs = { ... }
    varargs[4] = 3 -- default radius to 3
    return addModelClump(pebbleModels, 2, 3, 1.5, 3, unpack(varargs))
  end
  return addModelClump(pebbleModels, 2, 3, 1.5, 3, ...)
end



addGrassClump("nest.ground",   11,    0.5, nil, 5.25)
addGrassClump("nest.ground",   -7,   -6)
addGrassClump("nest.ground",   -3,  -17)
addGrassClump("nest.ground",    8,   -6)
addGrassClump("nest.ground",   14,  -19)
addGrassClump("nest.ground",   -9,    5)
addGrassClump("nest.ground",    8,    7)
addGrassClump("nest.ground",    7,  -15)

addPebbleClump("nest.ground",   4,  -18)
addPebbleClump("nest.ground",  20,  -24)
addPebbleClump("nest.ground", -16,  -16)
addPebbleClump("nest.ground", -14,   -3.5)
addPebbleClump("nest.ground",  13,    6)
addPebbleClump("nest.ground", -13,  -25.5)
addPebbleClump("nest.ground",   9,  -18)

return mapData