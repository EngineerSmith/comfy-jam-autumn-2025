local player = {
  lookAt = { 0, -5, 20 }, -- -1e-5
  magnet = 0.5, -- magnet * playerCharacter.size = effect radius
  isInputBlocked = false,
  chargingValue = 0,

  dashDuration = 0.10,
  dashSpeedMultiplier = 10,
  dashTimer = 0,
  chargeDX = 0,
  chargeDY = 0,

  counter = 0,
}

-- 4 frames, 0.3 s per frame
local chargingTime = 4 * 0.3 -- takes n seconds to charge

local g3d = require("libs.g3d")

local input = require("util.input")
local logger = require("util.logger")
local slickHelper require("util.slickHelper")
local audioManager = require("util.audioManager")

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

local distanceToPlayerSqu = function(x, y)
  local pX, pY = player.getPosition()
  local dx, dy = x - pX, y - pY
  return dx * dx + dy * dy
end

local isValidPositionalTable = function(tbl)
  return type(tbl) == "table" and type(tbl.x) == "number" and type(tbl.y) == "number"
end

local inPhase = false
player.update = function(dt)
  if not player.character then
    lookAt(player.getPosition())
    return
  end

  if input.baton:pressed("debugButton") then
    inPhase = not inPhase
    if inPhase then
      print("Entered phase (collision bypass)")
    else
      print("Exited phase (collision check on)")
    end
  end

  if player.dashTimer > 0 then
    local dashSpeed = player.character.speed * player.dashSpeedMultiplier
    local startX, startY = player.getPosition()
    local dashDX = player.dashNormalX * dashSpeed * dt
    local dashDY = player.dashNormalY * dashSpeed * dt
    if player.character:canMoveBy(dashDX, dashDY, "touch") then
      local _, smashables = player.character:getTagsBetween(startX, startY, dashDX, dashDY, "touch")
      for _, smashable in ipairs(smashables) do
        smashable:smashed()
      end
      player.character:move(dashDX, dashDY, "touch")

      player.dashTimer = player.dashTimer - dt
      if player.dashTimer <= 0 then
        player.dashTimer = 0
        player.character:setState("idle")
        player.isInputBlocked = false
      end
    else
      local tags, smashables = player.character:getTagsBetween(startX, startY, dashDX, dashDY, "touch")
      for _, smashable in ipairs(smashables) do
        smashable:smashed()
      end
      local _, hits = player.character:move(dashDX, dashDY, "touch") -- Attempt to move as close as possible to collision point
      player.dashTimer = 0
      player.character:setState("bonk")
      player.isInputBlocked = false
      if tags then
        for _, tag in ipairs(tags) do
          if tag.audio then
            audioManager.play(tag.audio, 1.0)
          else
            audioManager.play(slickHelper.tags["WALL"].audio, 1.0)
          end
        end
      end
      if hits then
        if #hits > 1 then
          table.sort(hits, function(a, b)
            local aValid = isValidPositionalTable(a)
            local bValid = isValidPositionalTable(b)
            if not aValid and     bValid then return false end
            if     aValid and not bValid then return true  end
            if not aValid and not bValid then return false end

            local magA = distanceToPlayerSqu(a.x, a.y)
            local magB = distanceToPlayerSqu(b.x, b.y)
            return magA < magB
          end)
        end
        local target = hits[1]
        if type(target) == "table" and target.onBonkScriptID then
          require("src.scripting").startScript(target.onBonkScriptID)
        end
      end
    end

    lookAt(player.getPosition())
    return
  end

  if player.isInputBlocked then
    lookAt(player.getPosition())
    return
  end

  local inputX, inputY = input.baton:get("move")
  local moveX, moveY = -inputX, -inputY
  local inputCharge = input.baton:get("charge")

  if player.character.state ~= "bonk" and player.character.state ~= "dash" then
    if inputCharge == 0 then
      if player.chargingValue >= 0.9 then -- Release dash!
        player.dashNormalX = player.chargeDX
        player.dashNormalY = player.chargeDY
        player.dashTimer = player.dashDuration
        player.character:setState("dash")
        audioManager.play("audio.fx.woosh", 1.0)
        player.isInputBlocked = true
      elseif player.chargingValue >= 0.25 then
        player.dashNormalX = player.chargeDX
        player.dashNormalY = player.chargeDY
        player.dashTimer = player.dashDuration / 3
        player.character:setState("dash")
        audioManager.play("audio.fx.woosh", 0.5)
        player.isInputBlocked = true
      elseif player.chargingValue ~= 0 then -- Accidental taps
        player.character:setState("idle")
      end
      player.chargingValue = 0
      player.counter = 0
      player.chargeDX, player.chargeDY = 0, 0
    else
      player.character:setState("charging")
      player.chargingValue = player.chargingValue + inputCharge * dt / chargingTime

      if moveX ~= 0 or moveY ~= 0 then
        local mag = math.sqrt(moveX * moveX + moveY * moveY)
        if mag > 0.4 then
          player.character:faceDirection(moveX, moveY)
          local angle = player.character:getFacingDirection()
          player.chargeDX = math.cos(angle)
          player.chargeDY = math.sin(angle)
        end
      end

      if player.chargingValue * dt < 0.01 and player.chargeDX == 0 and player.chargeDY == 0 then
        local angle = player.character:getFacingDirection()
        player.chargeDX = math.cos(angle)
        player.chargeDY = math.sin(angle)
      end

      if player.chargingValue > 1 then
        player.chargingValue = 1
        if player.character.currentFrame % 4 == 0 then
          player.counter = player.counter - 1
          if player.counter <= 0 then
            player.counter = 4
            audioManager.play("audio.fx.upgradeSuccess", 0.75)
          end
        end
      elseif player.character.frameChanged then
        audioManager.play("audio.fx.upgradeSuccess", 0.5)
      end
    end

    if player.chargingValue == 0 then
      local x, y = input.baton:get("move")
      local dx, dy = moveX * dt * player.character.speed, moveY * dt * player.character.speed
      if dx ~= 0 or dy ~= 0 then
        player.character:move(dx, dy, inPhase)
      end
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