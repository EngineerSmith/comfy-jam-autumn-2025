local player = { }

local input = require("util.input")

player.setCharacter = function(character)
  player.character = character
end

player.update = function(dt)
  local x, y = input.baton:get("move")
  local dx, dy = x * dt * player.character.speed, y * dt * player.character.speed
  player.character:move(dx, dy)
end

player.getPosition = function()
  local x, y, z = 0, 0, 0
  local char = player.character
  if char then
    x, y, z = char.x, char.y, char.z
  end
  return x, y, z
end

return player