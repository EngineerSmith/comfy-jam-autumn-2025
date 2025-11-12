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
  },
  colliders = {
    -- Nest
    { levels = { "nest.ground" }, shape = "rectangle", x = -30, y = -22, width = 60, height = 3, tag = "WALL" }, -- South wall
    { levels = { "nest.ground" }, shape = "rectangle", x = -30, y =  32, width = 60, height = 3, tag = "WALL" }, -- North wall
    { levels = { "nest.pot" }, shape = "rectangle", x = 23, y = -5.5, width = 5, height = 1, tag = "WALL" },
    { levels = { "nest.pot" }, shape = "rectangle", x = 31,   y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(180-25) },
    { levels = { "nest.pot" }, shape = "rectangle", x = 21,   y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(180+25) },
    { levels = { "nest.pot" }, shape = "rectangle", x = 30.5, y = 0, width = 1, height = 5, tag = "WALL", rz = math.rad(    25) },
    { levels = { "nest.pot" }, shape = "rectangle", x = 19.5, y = .5, width = 1, height = 5, tag = "WALL", rz = math.rad(   -25) },
  },
  collectables = {
    { level = "nest.ground", x =  0, y = 10, tag = "GOLDEN_LEAF", zone = "nest" }, -- behind nest pot
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
    { level = "nest.pot",    x = 25.5, y = 0.5, tag = "GOLDEN_LEAF", zone = "nest" }, -- on top of the large pot to show off different levels
    { level = "nest.ground", x = 18, y = -.5, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = 19, y = 8, tag = "LEAF", zone = "nest" },
    { level = "nest.ground", x = -25, y = -14, tag = "GOLDEN_LEAF", zone = "nest" }, -- Hidden under cabbage on the left of the nest pot
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
      -- TODO cutscene
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
    }
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

require("assets.level.nest_ground")
require("assets.level.zone1")

return mapData