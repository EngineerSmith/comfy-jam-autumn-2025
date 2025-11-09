local helper = require("assets.level.helper")

local mapData = {
  levels = {
    ["nest.ground"] = { x = -100, y = -100, z = 0, width = 200, height = 200 },
    ["nest.pot"] = { x = 20, y = -5, z = 4, width = 12, height = 12 },
  },
  transitions = {
    {
      x = 24, y = 6, width = 3, height = 6.0,
      edgeMap = { top = "nest.ground", bottom = "nest.pot" }
    }
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
      model = "model.flower_pot.small",  level = "nest.ground", x = -10, y = 20, z = 0, scale = 28, ry = math.rad(-90), rz = math.rad(-20+180),
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
    -- { model = "model.plant.leaf", level = "nest.ground", x = 0, y = -10, scale = 10 },
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
    --- Transition ramp; nest.ground <-> nest.pot
    {
      model = "model.log", level = "nest.ground", x = 25.5, y = 8, scale = 11, z = 0, rx = math.rad(-30),
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = 12, y = 12, scale = 23, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.rock.large.1", level = "nest.ground", x = -9, y = 37, z = -0.14, scale = 25, rz = math.rad(43.5+180), noScaleZ = true,
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
    { levels = { "nest.ground" }, shape = "rectangle", x = -30, y =  32, width = 60, height = 3, tag = "WALL" }, -- North wall
    { levels = { "nest.pot"}, shape = "rectangle", x = 23, y = -5.5, width = 5, height = 1, tag = "WALL" },
    { levels = { "nest.pot"}, shape = "rectangle", x = 31,   y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(180-25) },
    { levels = { "nest.pot"}, shape = "rectangle", x = 21,   y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(180+25) },
    { levels = { "nest.pot"}, shape = "rectangle", x = 30.5, y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(    25) },
    { levels = { "nest.pot"}, shape = "rectangle", x = 19.5, y = .5, width = 1, height = 5, tag = "WALL", rz = math.rad(   -25) },
  },
  collectables = {
    { level = "nest.ground", x =  0, y = 10, tag = "GOLDEN_LEAF", zone = "nest" },
    { level = "nest.ground", x =  0, y = 13, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -3, y = 10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x =  3, y = 10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -14.5, y = -2, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -9, y = -11.5, tag = "LEAF", zone = "nest"  },
    { level = "nest.ground", x = -17.5, y = -8, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -14, y = -17, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 12.5, y = -12, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 23, y = -10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 31, y = -6, tag = "LEAF", zone = "nest" },
    { level = "nest.pot",    x = 25.5, y = 0.5, tag = "GOLDEN_LEAF", zone = "nest" }, -- pot large
    { level = "nest.ground", x = 18, y = -.5, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 19, y = 8, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -25, y = -14, tag = "GOLDEN_LEAF", zone = "nest" },
    { level = "nest.ground", x = -1, y = 17, tag = "LEAF", zone = "nest" },
  },
  signposts = {
    { level = "nest.ground", x = 0, y = -7.4, z = 4, content = "Press [button.interact]to enter Nest", radius = 3.5 },
    { level = "nest.ground", x = -8, y = -6.5, z = 3, content = "[collectable_count.nest]", radius = 5.1 },
    { level = "nest.ground", x = -23, y = 0, z = 3, content = "[collectable_count.zone_1]", radius = 5.5, rz =  math.rad(20) },
    { level = "nest.ground", x =  29.5, y = -6, z = 3, content = "[collectable_count.zone_2]", radius = 5.5, rz = -math.rad(30) },
  },
  interactions = {
    { level = "nest.ground", x = 0, y = -8, radius = 3.0, scriptID = "enter.pot" },
  },
  scripts = {
    ["enter.pot"] = {
      { "lock" },
      { "moveTo", "Hedgehog.Player", 0, -8 },
      { "wait" },
      { "glideBy", "Hedgehog.Player", 0, 3 },
      { "sleep", 0.2 },
      { "transition", "CircularWipe.Out", 1.0 },
      { "wait" },
      { "changeStage", "nest" },
      { "sleep", 5e-2 },
      { "transition", "CircularWipe.In", 1.0 },
      { "wait" },
      -- { "unlock" },
    },
    ["exit.pot"] = {
      -- { "lock" },
      { "transition", "CircularWipe.Out", 1.0 },
      { "wait" },
      { "changeStage", "world" },
      { "transition", "CircularWipe.In", 1.0 },
      { "sleep", 0.2 },
      { "glideBy", "Hedgehog.Player", 0, -3 },
      { "wait" },
      { "unlock" },
    },
    ["event.newgame"] = { isMandatory = true, -- ran when a new game is started

    },
    -- Example interaction script
    ["interact.bed"] = { isMandatory = true,
      { "if", "if.nest.bed.level.0", 2, 4 },
      { "move", "ai", 0, 0 }, -- animation for level 0 bed
      { "goto", -1, },
      { "if", "if.nest.bed.level.1", 5, -1 },
      { "move", "ai", 0, 0 }, -- animation for level 1 bed
      { "ai.finishScript" }, -- tell the ai, that the script has finished
    },
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

helper.addPlant("nest.ground", 2.5, -17.5)
helper.addPlant("nest.ground", -8, -16)
helper.addPlant("nest.ground", -8, -3)
helper.addPlant("nest.ground", -20, -12)
helper.addPlant("nest.ground", 18, -17)
helper.addPlant("nest.ground", 24, -15.5)
helper.addPlant("nest.ground", 5, -7.5)
helper.addPlant("nest.ground", 10.5, -4.5)
helper.addPlant("nest.ground", 29, -11)
helper.addPlant("nest.ground", 23.25, 11.25)

helper.placeDirtPath("nest.ground", love.math.newBezierCurve(20, -4.5, 16, 0, 20, 9))

helper.addGrassClump("nest.ground", 22.5, 6.5)
helper.addGrassClump("nest.ground", 17.5, 14)
helper.addGrassClump("nest.ground", 23.5, -6)
helper.addGrassClump("nest.ground", 12, -8)
helper.addGrassClump("nest.ground", 15.5, 0)

helper.addPlant("nest.ground", 15, 7)
helper.addPlant("nest.ground", 20.6, 2.5)
helper.addPlant("nest.pot", 22.9, 2.1, -1)

helper.addSmallRock("nest.ground", -5.5, -9)
helper.addSmallRock("nest.ground", -8, -17.5)
helper.addSmallRock("nest.ground", 17.5, -7)
helper.addSmallRock("nest.ground", 26.5, -5)
helper.addSmallRock("nest.ground", 0, 8)
helper.addGrassClump("nest.ground", 12.5, 15)
helper.addPebbleClump("nest.ground", -6.5, 10)
helper.addLargeRock("nest.ground", -32, -12.5)
helper.addLargeRock("nest.ground", 25, -24)
helper.addLargeRock("nest.ground", 35.5, -16.5)
helper.addSmallRock("nest.ground", 28, -18)
helper.addGrassClump("nest.ground", 24, -23, 1)
helper.addGrassClump("nest.ground", 32, -25, 0.5)
helper.addPebbleClump("nest.ground", 31, -20)

helper.addLargeRock("nest.ground", 5.5, 21)
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(-4.5, 15.5, -1.5, 16.5, -2.5, 21.5))
helper.addGrassClump("nest.ground", 4, 15)
helper.addGrassClump("nest.ground", -0.5, 19.5)
helper.addPlant("nest.ground", 2.5, 15)
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(-16, 5.5, -9, 11.5, -2.5, 11.5))
helper.addPlant("nest.ground", -6.5, 6)
helper.addSmallRock("nest.ground", -14, 3)
helper.addCabbage("nest.ground", -28, -17)
helper.addPlant("nest.ground", -26.5, -5)
helper.addLargeRock("nest.ground", 23, 22)
helper.addCabbage("nest.ground", 15, 25)
helper.addGrassClump("nest.ground", 24, 29.5)
helper.addCabbage("nest.ground", 33.5, 8)
helper.addSmallRock("nest.ground", 30, 6)
helper.addGrassClump("nest.ground", 29, 10.5)
helper.addPlant("nest.ground", 20.5, 17.5)
helper.addPebbleClump("nest.ground", 12, 20)
helper.addSmallRock("nest.ground", 11, 19)
helper.addGrassClump("nest.ground", 33.5, 2)
helper.addSmallRock("nest.ground", 0.5, 27)
helper.addGrassClump("nest.ground", -7, 25)
helper.addGrassClump("nest.ground", -1, 27)
helper.addPlant("nest.ground", -5.2, 23)
helper.addGrassClump("nest.ground", -10, 14)
helper.addLargeRock("nest.ground", -21, 15)
helper.addCabbage("nest.ground", -17, 20.5)
helper.addCabbage("nest.ground", -21, 33.5)
helper.addSmallRock("nest.ground", -15, 16)
helper.addGrassClump("nest.ground", -13.5, 25.5)
helper.addLargeRock("nest.ground", -27, 26)
helper.addCabbage("nest.ground", -25.5, 20)
helper.addGrassClump("nest.ground", -21.5, 19)
helper.addGrassClump("nest.ground", -19, 28)
helper.addPlant("nest.ground", -21, 19)
helper.addCabbage("nest.ground", -10.5, 30)
helper.addPlant("nest.ground", -16.5, 30.5)
helper.addGrassClump("nest.ground", -12, 19)
helper.addPlant("nest.ground", 0.5, 30)
helper.addGrassClump("nest.ground", 7, 28)
helper.addCabbage("nest.ground", 10, 33)
helper.addLargeRock("nest.ground", 21, 36)
helper.addGrassClump("nest.ground", 5, 39)
helper.addGrassClump("nest.ground", 0, 44)
helper.addSmallRock("nest.ground", 14.5, 37)
helper.addPebbleClump("nest.ground", 8.5, 37.5)
helper.addPlant("nest.ground", 7.5, 40.5)
helper.addLargeRock("nest.ground", 15, 38.5)
helper.addPlant("nest.ground", 17.5, 33.5)
helper.addPlant("nest.ground", 15.5, 31)
helper.addGrassClump("nest.ground", 15, 31.5)
helper.addCabbage("nest.ground", 31.5, 20.5)
helper.addGrassClump("nest.ground", 18, 23)
helper.addLargeRock("nest.ground", 37.5, 14.5)
helper.placeDirtPath("nest.ground", love.math.newBezierCurve(23, 16, 28, 8.5))
helper.addGrassClump("nest.ground", 29, 16)
helper.addPebbleClump("nest.ground", 27.5, 16)
helper.addPlant("nest.ground", 33, 13)


return mapData