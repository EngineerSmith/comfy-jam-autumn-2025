return {
  levels = {
    ["LevelA"] = { x = -200, y = -100, z =  0, width = 200, height = 200 },
    ["LevelB"] = { x =  100, y = -100, z = 10, width = 200, height = 200 },
  },
  transitions = {
    {
      x = 0, y = -50, width = 100, height = 100,
      edgeMap = { left = "LevelA", right = "LevelB" },
    },
  },
  models = {
    -- Surfaces
    { model = "model.surface.1", texture = "texture.prototype.2", level = "LevelA", x = -100, y = 0, z = -.1, },
    --
    {
      model = "model.stump.1", level = "LevelA", x = -100, y = 20, z = 0, scale = 20,
      collider = { levels = { "LevelA", "LevelB" }, shape = "circle", radius = 0.18, segments = 6, rotation = 90, tag = "LOG" },
    },
    {
      model = "model.stump.1", level = "LevelA", x = -180, y = 50, z = 0, scale = 20,
      collider = { levels = { "LevelA", "LevelB" }, shape = "rectangle", width = 0.36, height = 0.44, tag = "LOG" },
    },
  },
  colliders = {
    { levels = { "LevelA" }, shape = "rectangle", x = -50, y = -100, width = 10, height = 80, tag = "WALL" },
    { levels = { "LevelB" }, shape = "circle", x = 145, y = -105, radius = 12.5, segments = 16, tag = "WALL" },
  },
  collectables = {
    { level = "LevelA", x = -125, y = 25, tag = "LEAF" },
    { level = "LevelA", x = -125, y = 20, tag = "LEAF" },
    { level = "LevelA", x = -125, y = 15, tag = "LEAF" },
    { level = "LevelA", x = -125, y = 10, tag = "LEAF" },
    { level = "LevelA", x = -125, y = 05, tag = "LEAF" },
    { level = "LevelA", x = -125, y = 00, tag = "LEAF" },
    { level = "LevelA", x = -120, y = 25, tag = "LEAF" },
    { level = "LevelA", x = -120, y = 20, tag = "LEAF" },
    { level = "LevelA", x = -120, y = 15, tag = "LEAF" },
    { level = "LevelA", x = -120, y = 10, tag = "LEAF" },
    { level = "LevelA", x = -120, y = 05, tag = "LEAF" },
    { level = "LevelA", x = -120, y = 00, tag = "LEAF" },
  },
  characters = {
    ["Player.Hedgehog"] = {
      file = "assets/characters/hedgehog/init.lua",
      level = "LevelA",
      x = -100, y = 0,
    }
  },
  playerCharacter = "Player.Hedgehog",
}