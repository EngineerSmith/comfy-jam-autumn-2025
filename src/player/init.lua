local player = { }

local input = require("util.input")

player.setCharacter = function(character)
  player.character = character
end

player.update = function(dt)
  local x, y = input.baton:get("move")
  local dx, dy = x * dt * player.character.speed, y * dt * player.character.speed
  player.character:move(dx, dy)
  player.character:update(dt)
end

player.draw = function()
  player.character:draw()
end

return player