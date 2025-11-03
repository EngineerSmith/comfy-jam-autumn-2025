local player = {
  lookAt = { 0, -5, 15 }, -- -1e-5
  magnet = 1, -- magnet * playerCharacter.size = effect radius
}

local g3d = require("libs.g3d")

local input = require("util.input")

player.setCharacter = function(character)
  player.character = character
end

player.update = function(dt)
  local x, y = input.baton:get("move")
  local dx, dy = -x * dt * player.character.speed, -y * dt * player.character.speed
  if dx ~= 0 or dy ~= 0 then
    player.character:move(dx, dy)
  end

  local x, y, z = player.getPosition()
  local atX, atY, atZ = unpack(player.lookAt)
  g3d.camera:current():lookAt(x + atX, y + atY, z + atZ, x, y, z)
end

player.getPosition = function()
  local x, y, z = 0, 0, 0
  if player.character then
    x, y, z = player.character.x, player.character.y, player.character.z
  end
  return x, y, z
end

return player