local player = {
  lookAt = { 0, -5, 20 }, -- -1e-5
  magnet = 0.5, -- magnet * playerCharacter.size = effect radius
  isInputBlocked = false,
}

local g3d = require("libs.g3d")

local input = require("util.input")

player.setCharacter = function(character)
  player.character = character
end

local lookAt = function(x, y, z)
  local atX, atY, atZ = unpack(player.lookAt)
  player.camera:lookAt(x + atX, y + atY, z + atZ, x, y, z)
end

player.initialisePlayerCamera = function()
  player.camera = g3d.camera.newCamera()
  player.camera.fov = math.rad(50)
  player.camera:updateProjectionMatrix()
  lookAt(player.getPosition())
end

player.setAspectRatio = function(aspectRatio)
  player.camera.aspectRatio = aspectRatio
  player.camera:updateProjectionMatrix()
end

local inPhase = false
player.update = function(dt)
  if player.character and not player.isInputBlocked then

    if input.baton:pressed("debugButton") then
      inPhase = not inPhase
      if inPhase then
        print("Entered phase")
      else
        print("Exited phase")
      end
    end

    local x, y = input.baton:get("move")
    local dx, dy = -x * dt * player.character.speed, -y * dt * player.character.speed
    if dx ~= 0 or dy ~= 0 then
      player.character:move(dx, dy, inPhase)
    end
  end

  lookAt(player.getPosition())
end

player.getPosition = function()
  local x, y, z = 0, 0, 0
  if player.character then
    x, y, z = player.character.x, player.character.y, player.character.z
  end
  return x, y, z
end

return player