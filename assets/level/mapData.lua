local helper = require("assets.level.helper")

local mapData = {
  levels = {
    ["nest.ground"] = { x = -100, y = -100, z = 0, width = 200, height = 200 },
  },
  transitions = {

  },
  models = {
    --- Nest
    -- { model = "model.surface.1", texture = "texture.prototype.2", level = "nest.ground", x = 0, y = 0, z = -.1 },
    { model = "model.surface.2", level = "nest.ground", x = 0, y = 0, z = -.1 },
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
    {
      model = "model.rock.large.1", level = "nest.ground", x = -20, y = -18, z = -0.14, scale = 10, rz = math.rad(38+180), noScaleZ = true,
      collider = {
        levels = { "nest.ground" }, shape = "multi", tag = "ROCK",
        { shape = "circle", x =  0,   y = -0.13, radius = 0.38 },
        { shape = "circle", x = -0.2, y =  0.35, radius = 0.15 },
      }
    },
    -- { model = "model.path.dirt.3", level = "nest.ground", x = 0, y = -10, scale = 2 },
    -- { model = "model.path.dirt.2", level = "nest.ground", x = 0, y = -7, z = -0.05, scale = 2.1, rz = math.rad(love.math.random(0,360)), noScaleZ = true, },
  },
  colliders = {
    -- Nest
    { levels = { "nest.ground" }, shape = "rectangle", x = -30, y = -22, width = 60, height = 3, tag = "WALL" }, -- South wall
  },
  collectables = {
    { level = "nest.ground", x =  0, y = 10, tag = "GOLDEN_LEAF", zone = "nest" },
    { level = "nest.ground", x =  0, y = 13, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -3, y = 10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x =  3, y = 10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -14.5, y = -2, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -9, y = -11.5, tag = "LEAF", zone = "nest", zOffset = 0.1 },
    { level = "nest.ground", x = -17.5, y = -8, tag = "LEAF", zone = "nest", zOffset = 0.1 },
    { level = "nest.ground", x = -14, y = -17, tag = "LEAF", zone = "nest" },
  },
  signposts = {
    { level = "nest.ground", x = 0, y = -7.4, z = 4, content = "Press [button.attack]to enter Nest", radius = 3.5 },
    { level = "nest.ground", x = -8, y = -6.5, z = 3, content = "[collectable_count.nest]", radius = 5.1 },
    { level = "nest.ground", x = -23, y = 0, z = 3, content = "[collectable_count.zone_1]", radius = 5.5, rz =  math.rad(20) },
    { level = "nest.ground", x =  22, y = 0, z = 3, content = "[collectable_count.zone_2]", radius = 5.5, rz = -math.rad(20) },
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
helper.mapData = mapData -- link so helper can populate mapData

helper.addGrassClump("nest.ground",   11,    0.5, nil, 5.25) -- Plant pot grass
helper.addGrassClump("nest.ground",   -7,   -6)
helper.addGrassClump("nest.ground",   -3,  -17)
helper.addGrassClump("nest.ground",    8,   -6)
helper.addGrassClump("nest.ground",   14,  -19)
helper.addGrassClump("nest.ground",   -9,    5)
helper.addGrassClump("nest.ground",    8,    7)
helper.addGrassClump("nest.ground",    7,  -15)
helper.addGrassClump("nest.ground",   22,  -13)
helper.addPebbleClump("nest.ground",   4,  -18)
helper.addPebbleClump("nest.ground",  20,  -24)
helper.addPebbleClump("nest.ground", -16,  -16)
helper.addPebbleClump("nest.ground", -14,   -3.5)
helper.addPebbleClump("nest.ground",  13,    6)
helper.addPebbleClump("nest.ground", -13,  -25.5)
helper.addPebbleClump("nest.ground",   9,  -18)
helper.addPebbleClump("nest.ground",  22,  -13)
helper.addGrassClump("nest.ground",  -12,  -16.5)
helper.addGrassClump("nest.ground",  -25,  -10)
helper.addPebbleClump("nest.ground", -24,  -19)
helper.addGrassClump("nest.ground",  -24,  -19)

-- helper.addLeafLine("nest.ground", "nest", -50, 0, -30, 0, 5)
-- helper.addLeafCircle("nest.ground", "nest", -40, 0, 15, 12)

helper.addPebbleClump("nest.ground", -10, -8)
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(0, -13, -15, -13, -23, -2))

return mapData