local character = require("src.character")

local lg = love.graphics

local path = "assets/characters/hedgehog/"
local idle = lg.newImage(path .. "hedgehog.png")
idle:setFilter("nearest", "nearest")
local walking = lg.newImage(path .. "hedgehog_walking.png")
walking:setFilter("nearest", "nearest")
local fidget = lg.newImage(path .. "hedgehog_fidget.png")
fidget:setFilter("nearest", "nearest")
local fidget2 = lg.newImage(path .. "hedgehog_fidget_2.png")
fidget2:setFilter("nearest", "nearest")
local fidget3 = lg.newImage(path .. "hedgehog_fidget_3.png")
fidget3:setFilter("nearest", "nearest")
local charging_start = lg.newImage(path .. "hedgehog_charging_start.png")
charging_start:setFilter("nearest", "nearest")
local charging_loop = lg.newImage(path .. "hedgehog_charging_loop.png")
charging_loop:setFilter("nearest", "nearest")
local bonk_finished = lg.newImage(path .. "hedgehog_bonk_finished.png")

return function()
  local hedgehog = character.create("hedgehog", 8, 5, 0.31, 0.47)
  hedgehog.color = { 1, 0, 0, 1 } -- debug

  hedgehog:setStateTexture("idle", "loop", idle, 1, 0)
  hedgehog:setStateTexture("walking", "loop", walking, 2, 0.2)
    hedgehog:setStateTexture("dash", "loop", walking, 2, 0.025)
  hedgehog:setStateTexture("idle_fidget", "start", fidget, 8, 0.2) -- idle_fidget use "start" to play once, others use "finish"
  hedgehog:setStateTexture("idle_fidget", "start", fidget2, 8, 0.2)
  hedgehog:setStateTexture("idle_fidget", "start", fidget3, 6, 0.1)
  hedgehog:setStateTexture("charging", "start", charging_start, 4, 0.3)
  hedgehog:setStateTexture("charging", "loop", charging_loop, 4, 0.05)
  hedgehog:setStateTexture("bonk", "finish", bonk_finished, 7, 0.05) -- plays once, then goes to idle

  return hedgehog
end
