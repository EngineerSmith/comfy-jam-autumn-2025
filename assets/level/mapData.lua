return {
  levels = { -- width, height, zLevel, posX, posY }
    ["Ground"]   = { 200, 200,  0,   0,  0 },
    ["Bridge"]   = {  50, 400, 10, 100, 50 },
    ["TowerTop"] = { 150, 150, 20, 200,  0 },
  },
  transitions = {
    {
      minX = 150, minY = 20, maxX = 250, maxY = 50,
      edgeMap = { left = "Ground", right = "Bridge" },
    },
    {
      minX = 100, minY = 250, maxX = 150, maxY = 300,
      edgeMap = { top = "TowerTop", bottom = "Bridge" },
    },
  },
  characters = {
    ["Hedgehog"] = {
      file = "assets/characters/hedgehog/init.lua",
      level = "Ground",
      posX = 0, posY = 0,
    }
  },
  playerCharacter = "Hedgehog",
}