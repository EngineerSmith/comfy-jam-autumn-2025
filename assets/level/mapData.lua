local helper = require("assets.level.helper")

local mapData = {
  levels = {
    ["nest.ground"] = { x = -100, y = -100, z = 0, width = 200, height = 200 },
    ["nest.pot"] = { x = 20.5, y = -4.5, z = 4, width = 10, height = 10 },
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
      model = "model.flower_pot.large", level = "nest.ground", x = 25.5, y = 0.5, z = 0, scale = 20,
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.225, segments = 6, tag = "POT" },
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
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = -18, y = -26.5, scale = 25, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = 12.5, y = -23, scale = 28, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = -2, y = -25, scale = 23, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = 15, y = -5, scale = 15, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
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
    { level = "nest.ground", x = 12.5, y = -11.5, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 23, y = -10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 31, y = -6, tag = "LEAF", zone = "nest" },
    { level = "nest.pot",    x = 25.5, y = 0.5, tag = "GOLDEN_LEAF", zone = "nest" }, -- pot large
  },
  signposts = {
    { level = "nest.ground", x = 0, y = -7.4, z = 4, content = "Press [button.attack]to enter Nest", radius = 3.5 },
    { level = "nest.ground", x = -8, y = -6.5, z = 3, content = "[collectable_count.nest]", radius = 5.1 },
    { level = "nest.ground", x = -23, y = 0, z = 3, content = "[collectable_count.zone_1]", radius = 5.5, rz =  math.rad(20) },
    { level = "nest.ground", x =  29.5, y = -6, z = 3, content = "[collectable_count.zone_2]", radius = 5.5, rz = -math.rad(30) },
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
helper.addGrassClump("nest.ground", 25.5,    0.5, 3.5, 3) -- Plant pot large grass
helper.addGrassClump("nest.ground", 25.5,    1.5, 3.5, 3) -- Plant pot large grass
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
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(-2, -13, -15, -13, -23, -2))
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(2, -13, 19, -12.5, 29.5, -7))
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(0, -13.5, 0, -8))

helper.addPebbleClump("nest.ground", -25, -26)
helper.addPebbleClump("nest.ground", -9, -30)
helper.addGrassClump("nest.ground", -9, -29)
helper.addGrassClump("nest.ground", 19.5, -28)

return mapData