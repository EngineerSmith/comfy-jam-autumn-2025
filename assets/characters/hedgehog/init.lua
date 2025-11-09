local character = require("src.character")

local idle = love.graphics.newImage("assets/characters/hedgehog/hedgehog.png")
idle:setFilter("nearest", "nearest")
local walking = love.graphics.newImage("assets/characters/hedgehog/hedgehog_walking.png")
walking:setFilter("nearest", "nearest")
local fidget = love.graphics.newImage("assets/characters/hedgehog/hedgehog_fidget.png")
fidget:setFilter("nearest", "nearest")
local fidget2 = love.graphics.newImage("assets/characters/hedgehog/hedgehog_fidget_2.png")
fidget2:setFilter("nearest", "nearest")
local fidget3 = love.graphics.newImage("assets/characters/hedgehog/hedgehog_fidget_3.png")
fidget3:setFilter("nearest", "nearest")

return function()
  local hedgehog = character.create("hedgehog", 8, 5, 0.31, 0.47)
  hedgehog.color = { 1, 0, 0, 1 } -- debug

  hedgehog:setStateTexture("idle", idle, 1, 0)
  hedgehog:setStateTexture("walking", walking, 2, 0.2)
  hedgehog:setStateTexture("idle_fidget", fidget, 8, 0.2)
  hedgehog:setStateTexture("idle_fidget", fidget2, 8, 0.2)
  hedgehog:setStateTexture("idle_fidget", fidget3, 6, 0.1)

  return hedgehog
end
