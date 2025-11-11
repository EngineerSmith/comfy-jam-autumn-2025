local behaviours = { }

local flux = require("libs.flux")

local audioManager = require("util.audioManager")
-- audioManager.play("audio.fx.softImpact")

local rateLimitHistory = { }
local playRateLimited = function(assetKey, limit, timeWindow, volumeMod)

  if volumeMod == 0 then
    return -- nothing to play if volume is 0
  end

  if not rateLimitHistory[assetKey] then
    rateLimitHistory[assetKey] = { }
  end
  local history = rateLimitHistory[assetKey]
  local currentTime = love.timer.getTime()

  local oldestIndex = 1
  for i, timestamp in ipairs(history) do
    if currentTime - timestamp >= timeWindow then
      oldestIndex = i + 1
    else
      break
    end
  end

  if oldestIndex > 1 then
    for i = 1, oldestIndex - 1 do
      table.remove(history, 1)
    end
  end

  if #history < limit then
    table.insert(history, currentTime)
    audioManager.play(assetKey, volumeMod)
    return true
  else
    return false
  end
end

behaviours["play_ball"] = {
  initialise = function(ai, ballObject)
    return {
      character = ai.character,
      characterSpeed = ai.speed,
      ball = ballObject,
      kicksLeft = 3,
      step = "move_to_ball",
      timer = 0,
      canHitFloor = false,
      -- Physics State
      vx = 0, vy = 0, vz = 0,
      gravity = -2.0,
      friction = 0.8,
      finalKickFriction = 0.4, -- harsh friction for final kick before we transition back
      restitution = 0.7,
      boundingRadius = 1.67,
      --
      MIN_IMPACT_VEL = 0.1,
      MAX_IMPACT_VEL = 2.0,
    }
  end,
  update = function(dt, behaviourState)
    local state = behaviourState
    local char = state.character
    local ball = state.ball

    if behaviourState.kicksLeft <= 0  and state.vx * state.vx + state.vy * state.vy < 0.001 and ball.z <= 0.01 then
      ball:setState("idle")
      return false
    end

    state.vz = state.vz + state.gravity * dt

    if ball.z <= 0.01 then
      local friction = state.friction
      if state.kicksLeft <= 0 then
        friction = state.finalKickFriction
      end
      state.vx = state.vx * (friction ^ dt)
      state.vy = state.vy * (friction ^ dt)
    end

    ball.x = ball.x + state.vx * dt
    ball.y = ball.y + state.vy * dt
    ball.z = ball.z + state.vz * dt

    if ball.z < 0 then
      if state.canHitFloor then
        playRateLimited("audio.fx.softImpact", 3, 1.0)
        state.canHitFloor = false
      end

      ball.z = 0
      ball.vz = -state.vz * state.restitution
      if math.abs(state.vz) < 0.1 then -- dampen
        state.vz = 0
      end
    end

    -- Check wall bounce
    local ballMag = math.sqrt(ball.x * ball.x + ball.y * ball.y)
    if ballMag > state.boundingRadius then
      local normalX, normalY = ball.x / ballMag, ball.y / ballMag

      -- Project velocity onto normal vector to check direction
      local velNorm = state.vx * normalX + state.vy * normalY
      if velNorm > 0 then -- if moving outwards
        state.vx = state.vx - 2 * velNorm * normalX * state.restitution
        state.vy = state.vy - 2 * velNorm * normalY * state.restitution

        local penetration = ballMag - state.boundingRadius
        ball.x = ball.x - penetration * normalX
        ball.y = ball.y - penetration * normalY

        local volumeMod = math.min(1.0, math.max(0.0, (velNorm - state.MIN_IMPACT_VEL) / (state.MAX_IMPACT_VEL - state.MIN_IMPACT_VEL)))
        playRateLimited("audio.fx.softImpact", 3, 1.0, volumeMod)
      end
    end

    local planarSpeedSqu = state.vx * state.vx + state.vy * state.vy
    if planarSpeedSqu > 0.001 then
      ---- animation speed
      local MAX_SPEED_FOR_ANIM = 2.0 -- speed where animation is fastest
      local MAX_FRAME_TIME = 0.20 -- slowest frame time
      local MIN_FRAME_TIME = 0.02 -- fastest frame time

      local normalisedSpeed = math.min(1, math.sqrt(planarSpeedSqu) / MAX_SPEED_FOR_ANIM)
      local invSpeed = 1.0 - normalisedSpeed
      local curvedInvSpeed = invSpeed ^ 1.5

      local frameTimeDiff = MAX_FRAME_TIME - MIN_FRAME_TIME
      local dynamicFrameTime = MIN_FRAME_TIME + (curvedInvSpeed * frameTimeDiff)

      local walkingStateData = ball.stateTextures["walking"]
      if walkingStateData then
        walkingStateData["loop"][1].frameTime = dynamicFrameTime
      end

      ---- flip
      local currentFlip = ball.flip
      local newFlip = state.vx > 0
      if currentFlip ~= newFlip then
        ball.flip = newFlip
        if ball.flipTween then
          ball.flipTween:stop()
        end
        if not ball.flip then
          ball.flipRZ = math.rad(0)
          ball.flipTween = flux.to(ball, 0.15, { flipRZ = math.rad(-180) })
        else
          ball.flipRZ = math.rad(-180)
          ball.flipTween = flux.to(ball, 0.15, { flipRZ = math.rad(0) })
        end
      end
      ball.movedPreviousFrame = true
        -- ball:setState("walking")
    else
      ball:setState("idle")
    end

    if state.step == "move_to_ball" then
      local LOOKAHEAD_TIME = 0.5
      local planarSpeed = math.sqrt(state.vx*state.vx + state.vy*state.vy)

      local targetX, targetY = ball.x, ball.y
      local distToActualBall = math.sqrt((ball.x - char.x)^2 + (ball.y - char.y)^2)
      local moveSpeed = state.characterSpeed * dt

      if planarSpeed > 0.1 and ball.z < 0.5 and distToActualBall < moveSpeed * 4 then
        targetX = ball.x + state.vx * LOOKAHEAD_TIME
        targetY = ball.y + state.vy * LOOKAHEAD_TIME
      end

      local dx, dy = targetX - char.x, targetY - char.y
      local mag = math.sqrt(dx * dx + dy * dy)

      -- close enough to kick
      if distToActualBall < moveSpeed * 5 then
        if state.kicksLeft > 0 then
          -- stop ball
          state.vx, state.vy, state.vz = 0, 0, 0 -- ensures we don't build up too much speed
          --
          local kickForce = 2.0
          local kickDX, kickDY = -char.x, -char.y
          local kickAngle = math.atan2(kickDY, kickDX) + love.math.random() * 1.5 - 0.75

          state.vx = kickForce * math.cos(kickAngle)
          state.vy = kickForce * math.sin(kickAngle)
          state.vz = 1.25 + love.math.random() * 0.5 - 0.25

          state.canHitFloor = true

          state.kicksLeft = state.kicksLeft - 1
          playRateLimited("audio.fx.softImpact", 3, 1.0)
        end
        state.step = "wait_for_ball"
        state.timer = 0
      else
        local normX, normY = dx / mag, dy / mag
        char:move(normX * moveSpeed, normY * moveSpeed, false)
      end
    elseif state.step == "wait_for_ball" then
      state.timer = state.timer + dt
      local planarSpeedSqu = state.vx * state.vx + state.vy * state.vy
      if (planarSpeedSqu < 0.1 and ball.z < 0.05) or state.timer > 2.0 then -- todo revert; set higher to test my theory
        if state.kicksLeft > 0 then
          state.step = "move_to_ball"
        else
          return false -- finished playing
        end
      end
    end
    return true -- behaviour is ongoing
  end,
}

return behaviours