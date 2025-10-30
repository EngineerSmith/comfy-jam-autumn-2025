return {
  levels = { -- x, y, width, height, z }
    ["LevelA"] = { -200, -100, 200, 200,  0 },
    ["LevelB"] = {  100, -100, 200, 200, 10 },
  },
  transitions = {
    {
      0, -50, 100, 100,
      edgeMap = { left = "LevelA", right = "LevelB" },
    },
  },
  characters = {
    ["Player.Hedgehog"] = {
      file = "assets/characters/hedgehog/init.lua",
      level = "LevelA",
      posX = -100, posY = 0,
    }
  },
  playerCharacter = "Player.Hedgehog",
}