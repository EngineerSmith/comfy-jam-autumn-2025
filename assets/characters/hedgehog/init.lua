local character = require("src.character")

local img = love.graphics.newImage("assets/characters/hedgehog/hedgehog.png")
-- local img = love.graphics.newImage("assets/characters/hedgehog/white.png")
img:setFilter("nearest", "nearest")

return function()
  local hedgehog = character.create("hedgehog", 15, 5, 0.2, 0.47)
  hedgehog.color = { 1, 0, 0, 1 } -- debug

  hedgehog:setStateTexture("idle", img, 1, 0)

  return hedgehog
end
