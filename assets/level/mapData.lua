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
    {
      model = "model.stump.1", level = "LevelA", x = -150, y = 50, z = 0, scale = 5,
      collider = { levels = { "LevelA", "LevelB" }, shape = "circle", radius = 0.22, segments = 16, tag = "LOG", },
    },
    {
      model = "model.stump.1", level = "LevelA", x = -180, y = 50, z = 0, scale = 5,
      collider = { levels = { "LevelA", "LevelB" }, shape = "rectangle", width = 0.44, height = 0.44, tag = "LOG" },
    }
  },
  colliders = {
    { levels = { "LevelA" }, shape = "rectangle", x = -50, y = -100, width = 10, height = 200, tag = "WALL" },
    { levels = { "LevelB" }, shape = "circle", x = 145, y = -105, radius = 12.5, segments = 16, tag = "WALL" },
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