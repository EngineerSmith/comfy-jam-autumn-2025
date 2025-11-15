local helper = require("assets.level.helper")

local mapData = {
  levels = {
    ["nest.ground"] = { x = -60, y = -60, z = 0, width = 120, height = 120 },
    ["nest.pot"] = { x = 20, y = -5, z = 4, width = 12, height = 12 },
    ["zone1.ground"] = { x = -130, y = -50, z = 0, width = 100, height = 100 },
    ["zone1.upper"] = { x = -120, y = -20, z = 5, width = 80, height = 100 },
    ["zone1.rock"] = { x = -41.5, y = 12.5, z = 4.1, width = 3, height = 3 },
    ["tutorial.ground"] = { x = -35, y = -80, z = 0, width = 85, height = 60 },
    ["tutorial.upper"] = { x = 14, y = -50, z = 5, width = 15, height = 20 },
  },
  transitions = {
    {
      x = 24, y = 6, width = 3, height = 6,
      edgeMap = { top = "nest.ground", bottom = "nest.pot" }
    },
    {
      x = -32, y = -1, width = 3, height = 9,
      edgeMap = { left = "zone1.ground", right = "nest.ground" }
    },
    {
      x = -41.5, y = 4.75, width = 3.5, height = 7,
      edgeMap = { top = "zone1.rock", bottom = "zone1.ground" }
    },
    {
      x = -4, y = -23, width = 16, height = 2,
      edgeMap = { bottom = "tutorial.ground", top = "nest.ground" }
    },
    {
      x = 3.25, y = -38.5, width = 9.5, height = 4,
      edgeMap = { left = "tutorial.ground", right = "tutorial.upper" }
    },
  },
  models = {
    --- Nest
    -- { model = "model.surface.1", texture = "texture.prototype.2", level = "nest.ground", x = 0, y = 0, z = -.1 },
    { model = "model.surface.2", level = "nest.ground", x = 0, y = 0, z = -.1 },
    { model = "model.surface.2", level = "zone1.ground", x = -50, y = 0, z = -.1 },
    { model = "model.surface.2", level = "tutorial.ground", x = 15, y = -50, z = -.1 },
    { model = "model.surface.2", level = "tutorial.ground", x = 65, y = -50, z = -.1 },
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
    -- { -- Removed for tutorial zone
    --   model = "model.rock.large.1", level = "nest.ground", x = 0, y = -25, z = -0.14, scale = 25, rz = math.rad(43.5), noScaleZ = true,
    --   collider = {
    --     levels = { "nest.ground" }, shape = "multi", tag = "ROCK",
    --     { shape = "circle", x =  0,   y = -0.13, radius = 0.38 },
    --     { shape = "circle", x = -0.2, y =  0.35, radius = 0.15 },
    --   }
    -- },
    {
      model = "model.rock.large.1", level = "nest.ground", x = -20, y = -18, z = -0.14, scale = 10, rz = math.rad(38+180), noScaleZ = true,
      collider = {
        levels = { "nest.ground", "tutorial.ground" }, shape = "multi", tag = "ROCK",
        { shape = "circle", x =  0,   y = -0.13, radius = 0.38 },
        { shape = "circle", x = -0.2, y =  0.35, radius = 0.15 },
      }
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = -18, y = -26.5, scale = 25, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground", "tutorial.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = 12.5, y = -21, scale = 28, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground", "tutorial.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = -5.5, y = -23.5, scale = 23, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground", "tutorial.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    {
      model = "model.bush.cabbage", texture = "texture.foodKit.colorMap", level = "nest.ground", x = 15, y = -5, scale = 15, rz = love.math.random(0, 2 * math.pi),
      collider = { levels = { "nest.ground" }, shape = "circle", radius = 0.1, segments = 6, tag = "PLANT" },
    },
    { --- Transition ramp; nest.ground <-> nest.pot
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
    { --- Transition ramp; nest.ground <-> nest.pot
      model = "model.log", level = "zone1.ground", x = -40, y = 9, scale = 11, z = 0, rx = math.rad(30),
    },
    { -- This is the whole of level zone1.rock
      model = "model.rock.tall.1", level = "zone1.ground", x = -40, y = 13, scale = 6, rz = math.rad(-80),
      -- collider = { levels = { "zone1.ground" }, shape = "circle", radius = 0.25, segments = 6, tag = "ROCK" },
    },
    {
      model = "model.rock.tall.1", level = "zone1.ground", x = -49, y = 13, scale = 6, rz = math.rad(90),
      collider = { levels = { "zone1.ground" }, shape = "circle", radius = 0.25, segments = 6, tag = "ROCK" },
    },
    { --- Transition ramp; tutorial.upper <-> tutorial.ground (left)
      model = "model.log", level = "tutorial.ground", x = 9.5, y = -36.5, scale = 15, z = 0, rx = math.rad(-25), rz = math.rad(90),
    },
    { --- Transition ramp; tutorial.ground <-> tutorial.upper (right); position moved by gameplay script
      model = "model.log", level = "tutorial.ground", x = 41, y = -36.5, scale = 15, z = 5.25, rx = math.rad(90), rz = math.rad(90),
      onBonkScriptID = "bonk.tutorial", id = "tutorial.log",
      collider = { levels = { "tutorial.ground" }, x = 0.1, shape = "circle", radius = 0.1, segments = 6, tag = "LOG" },
    },
    { --- Transition ramp; zone1.upper <-> zone1.rock; position moved by gameplay script
      model = "model.log", level = "zone1.upper", x = -50.5, y = 13, scale = 13, z = 4.55, rx = math.rad(90), rz = math.rad(-90),
      onBonkScriptID = "bonk.zone1.upper", id = "zone1.upper.log",
      collider = { levels = { "zone1.upper" }, x = -0.1, shape = "circle", radius = 0.1, segments = 6, tag = "LOG" },
    },
  },
  colliders = {
    -- Nest
    -- { levels = { "nest.ground", "tutorial.ground" }, shape = "rectangle", x = -30, y = -22, width = 25, height = 3, tag = "WALL" }, -- South wall Left
    -- { levels = { "nest.ground", "tutorial.ground" }, shape = "rectangle", x =  12, y = -22, width = 25, height = 3, tag = "WALL" }, -- South wall Right
    { levels = { "nest.ground" }, shape = "rectangle", x = -30, y =  32, width = 60, height = 3, tag = "WALL" }, -- North wall
    { levels = { "nest.pot" }, shape = "rectangle", x = 23, y = -5.5, width = 5, height = 1, tag = "WALL" },
    { levels = { "nest.pot" }, shape = "rectangle", x = 31,   y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(180-25) },
    { levels = { "nest.pot" }, shape = "rectangle", x = 21,   y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(180+25) },
    { levels = { "nest.pot" }, shape = "rectangle", x = 30.5, y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(    25) },
    { levels = { "nest.pot" }, shape = "rectangle", x = 19.5, y = .5, width = 1, height = 5, tag = "WALL", rz = math.rad(   -25) },
    { levels = { "nest.ground", "zone1.ground", "tutorial.ground" }, shape = "rectangle", x = -31, y = -51, width = 1, height = 50, tag = "WALL" },
    -- { levels = { "nest.ground", "zone1.ground" }, shape = }
    { levels = { "zone1.ground" }, shape = "rectangle", x = -41.5, y = 11, width = 0.25, height = 2, tag = "ROCK" },
    { levels = { "zone1.ground", "zone1.rock" }, shape = "rectangle", x = -41.5, y = 14.5, width = 2, height = 0.25, tag = "ROCK" },
    { levels = { "zone1.rock" }, shape = "rectangle", x = -38.5, y = 12.5, width = 0.25, height = 2, tag = "ROCK" },
    { levels = { "zone1.upper" }, shape = "circle", x = -50, y=17.5, radius = 1, tag = "WALL" },
  },
  collectables = {
    { level = "nest.ground", x = -2, y = 17.5, tag = "GOLDEN_LEAF", zone = "nest" }, -- behind nest pot
    -- { level = "nest.ground", x =  0, y = 13, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -10.5, y = 9, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x =  7.5, y = 7.5, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -14.5, y = -2, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -9, y = -11.5, tag = "LEAF", zone = "nest"  },
    { level = "nest.ground", x = -17.5, y = -8, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -14, y = -17, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 12.5, y = -12, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 23, y = -10, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 31, y = -6, tag = "LEAF", zone = "nest" },
    { level = "nest.pot",    x = 25.5, y = 0.5, tag = "GOLDEN_LEAF", zone = "nest" }, -- on top of the large pot to show off different levels
    { level = "nest.ground", x = 18, y = -.5, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 19, y = 8, tag = "LEAF", zone = "nest" },
    -- { level = "nest.ground", x = -25, y = -14, tag = "GOLDEN_LEAF", zone = "nest" }, -- Hidden under cabbage on the left of the nest pot
    -- { level = "nest.ground", x = -1, y = 17, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -23.5, y = 0, tag = "LEAF", zone = "nest" },
  },
  smashables = { },
  signposts = {
    { level = "nest.ground", x =  0,     y =  -7.4, z = 4, content = "Press[button.interact]to enter Nest", radius = 3.5 },
    { level = "nest.ground", x = -8,     y =  -6.5, z = 3, content = "[collectable_count.nest]", radius = 5.1 },
    { level = "nest.ground", x = -23,    y =   0,   z = 3, content = "[collectable_count.zone_1]", radius = 5.5, rz =  math.rad(20) },
    { level = "nest.ground", x =  29.5,  y =  -6,   z = 3, content = "[collectable_count.zone_2]", radius = 5.5, rz = -math.rad(30) },
    { level = "nest.ground", x =   4.25, y = -22.5, z = 3, content = "[collectable_count.tutorial]", radius = 5.5 },
    { level = "tutorial.ground", x = 47, y = -32.5, z = 3, content = "Hold[button.charge]to bash logs", radius = 5.5 },
    { level = "tutorial.ground", x = 48, y = -50,   z = 3, content = "Use[button.move]to move", radius = 5.5 },
    { level = "tutorial.upper",  x = 23, y = -34.5, z = 3, content = "Hold[button.charge]to bash pots", radius = 5.5 },
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
    },
    ["exit.pot"] = {
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
      { "lock" },
      { "createNamedCollider", "zone1.rock", "zone1RockBlock", "circle", -42, 13, .5 },
      { "goto", -2}, -- debug jump
      { "setCutsceneCamera", -10, -25, 15, -10, -10, 3 },
      { "switchCamera", "cutscene" },
      { "glideTo", "Hedgehog.Player", -13, -10.5 },
      { "sleep", 1.0 },
      { "wait" },
      { "glideTo", "Hedgehog.Player", -6.5, -13 },
      { "lerpCameraTo", -10, -25, 15, 0, -10, -5, 4.5 },
      { "sleep", 0.9 },
      { "glideTo", "Hedgehog.Player", -1, -12.5 },
      { "sleep", 0.7 },
      { "glideTo", "Hedgehog.Player", 0, -9 },
      { "sleep", 0.5 },
      { "characterFace", "Hedgehog.Player", "north" },
      { "wait" },
      { "switchCamera", "player" },
      { "unlock" },
    },
    -- Example interaction script
    ["interact.bed"] = { isMandatory = true,
      { "moveAI",  0,  -0.4 },
      { "moveAI", -0.3, 0 },
      { "wait" }, { "sleep", 0.1 },
      { "moveAI",  0.6, 0 },
      { "wait" }, { "sleep", 0.1 },
      { "moveAI", -0.3, 0 },
      { "wait" }, { "sleep", 0.3 },
      { "aiState", "sleep" },
      { "sleep", 4 * 0.2 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 2 * 0.2 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.4 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.4 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.4 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.4 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.4 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.4 },
      { "playAudio", "audio.fx.snore" },
      { "sleep", 0.1 },
      { "aiState", "idle" },
      { "sleep", 8 * 0.2 + 0.05 },
      { "moveAI", 0, 0.4 },
      { "wait" }
    },
    ["ai.alert"] = {
      { "aiState", "alert" },
      { "sleep", 4 * 0.1 + 1 * 0.2 },
      { "aiFootstep" },
      { "sleep", 2 * 0.2 },
      { "aiFootstep" },
      { "sleep", 2 * 0.2 },
      { "aiFootstep" },
      { "sleep", 0.01 }, -- Make sure loop ends
      { "aiState", "idle" },
      { "sleep", 3 * 0.1 + 0.01 }
    },
    ["ai.jump"] = { -- Play two jump animations
      { "aiState", "jump" },
      { "sleep", 0.4 },
      { "aiFootstep" },
      { "sleep", 0.7 },
      { "aiState", "jump" },
      { "sleep", 0.4 },
      { "aiFootstep" },
      { "sleep", 0.7 },
    },
    ["bonk.tutorial"] = {
      { "lock" },
      { "setCutsceneCamera", 33.5, -46, 15, 33.5, -36, 2 },
      { "switchCamera", "cutscene" },
      { "lerpProp", "tutorial.log", 34.25, nil, 0, math.rad(25), nil, nil, 0.8 },
      { "removePropCollider", "tutorial.log" },
      { "removePropCollider", "tutorial.rock.logBlock" },
      { "addTransition", 31.0, -38.5, 9.75, 4, { left = "tutorial.upper", right = "tutorial.ground" } },
      { "sleep", 0.7 },
      { "playAudio", "audio.fx.impact.wood" },
      { "sleep", 1.3 },
      { "wait" },
      { "switchCamera", "player" },
      { "unlock" },
    },
    ["bonk.zone1.upper"] = {
      { "lerpProp", "zone1.upper.log", -44.8, nil, -3, math.rad(-10), nil, nil, 0.8 },
      { "removePropCollider", "zone1.upper.log" },
      { "removeNamedCollider", "zone1.rock", "zone1RockBlock" },
      { "addTransition", -49.5, 11.25, 7, 3.5, { right = "zone1.rock", left = "zone1.upper" } },
      { "sleep", 0.7 },
      { "playAudio", "audio.fx.impact.wood" },
      { "wait" },
    }
  },
  characters = {
    ["Hedgehog.Player"] = {
      file = "assets/characters/hedgehog/init.lua",
      level = "tutorial.ground",
      x = 44.5, y = -53,
    },
    ["Hedgehog.Debug"] = {
      file = "assets/characters/hedgehog/init.lua",
      level = "zone1.upper",
      x = -54, y = 6.5,
    },
    -- ["Hedgehog.Debug"] = {
    --   file = "assets/characters/hedgehog/init.lua",
    --   level = "tutorial.ground",
    --   x = 44.5, y = -53,
    -- },
  },
  playerCharacter = "Hedgehog.Player",
}
helper.mapData = mapData -- link so helper can populate mapData

require("assets.level.nest_ground")
require("assets.level.zone1")
helper.addPlant("nest.ground", 23.5, 27)
helper.addSmallRock("nest.ground", 21.5, 29)
require("assets.level.tutorial")

return mapData