local nest = { }

local lg = love.graphics

local g3d = require("libs.g3d")
local flux = require("libs.flux")

local input = require("util.input")
local cursor = require("util.cursor")
local assetManager = require("util.assetManager")
local audioManager = require("util.audioManager")

local ai = require("src.world.nest.ai")
local object = require("src.world.nest.object")

local SOUND_PULSE_CHARGE = "audio.fx.chip"
local SOUND_PURCHASE     = "audio.fx.upgradeSuccess"
local SOUND_DISABLE      = "audio.fx.errorBuzz"

nest.bedAssets = {
  [0] = "model.nest.interior.bed.0",
  [1] = "model.nest.interior.bed.1",
  [2] = "model.nest.interior.bed.2",
  [3] = "model.nest.interior.bed.3",
  [4] = "model.nest.interior.bed.4",
}

nest.bedLevels = {
  [0] = 5,
  [1] = 20,
  [2] = 20,
  [3] = 20,
  [4] = 20,
}

nest.bedButton = {
  text = "Upgrade Bed: %d leaves",
  percentage = 0,
  isHovered = false,
  pulseTimer = 0,
  minPulseDelay = 0.05, -- fastest
  maxPulseDelay = 0.20, -- slowest
  --
  wiggleSpeed = 30.0,
  wiggleMaxOffset = 3.0,
  wiggleMaxRotation = 0.05,
  --
  purchaseAnimationTime = 0.0,
  animationTimeMax = 0.4,
  cooldownTime = 1.0,
  cooldown = 0,
  --
  disabled = 0,
  disabledTime = 1.1,
}

local hedgehogTextureStates = {
  idle = { loop = { frames = 1, duration = 0 } },
  walking = { loop = { frames = 2, duration = 0.1 } },
  sleep = {
    start = { frames = 6 },
    loop  = { frames = 2 },
    exit  = { frames = 8 },
  },
  alert = {
    start = { frames = 4, duration = 0.1 },
    loop  = { frames = 6 },
    exit  = { frames = 3, duration = 0.1 },
  },
  jump = { start = { frames = 5 } },
}

local ballTextureStates = {
  idle = { loop = { frames = 1, duration = 0 } },
  walking = { loop = { frames = 8 } },
}

local setTextureStates = function(object, texturePath, textureStates)
  for stateName, subStates in pairs(textureStates) do
    local assetKeyPrefix = texturePath .. "." .. stateName
    for subState, properties in pairs(subStates) do
      local assetKey = assetKeyPrefix .. "." .. subState
      local tex = assetManager[assetKey]
      object:setStateTexture(stateName, subState, tex, properties.frames, properties.duration or 0.2)
    end
  end
end

nest.load = function()
  nest.bedLevel = -1 -- cutscene raises bedLevel to 0
  nest.bedVisualLevel = nest.bedLevel

  nest.bgShader = lg.newShader("src/world/vignette.glsl")
  nest.bgShader:send("centerColor", { 0.16, 0.11, 0.08 })
  nest.bgShader:send("edgeColor", { 0.008, 0.006, 0.005 })
  nest.bgMesh = lg.newMesh({
  --  x, y, u, v
    { 0, 0, 0, 0 }, -- Top left
    { 1, 0, 1, 0 }, -- Top right
    { 0, 1, 0, 1 }, -- Bottom left
    { 1, 1, 1, 1 }, -- Bottom right
  }, "strip", "static")
  nest.camera = g3d.camera.newCamera()
  nest.camera.fov = math.rad(70)
  nest.camera:updateProjectionMatrix()
  nest.camera:orbitalLookAt(nil, nil, 0, 0, 0.5, 2.7)

  nest.hedgehog = object.new()
  setTextureStates(nest.hedgehog, "sprite.hedgehog", hedgehogTextureStates)

  nest.ball = object.new(0.35)
  setTextureStates(nest.ball, "sprite.ball", ballTextureStates)

  nest.objects = {
    nest.hedgehog,
    nest.ball,
  }

  ai.addCharacterControl(nest.hedgehog)
  ai.addRandomScript("ai.jump")
  -- ai.addRandomScript("ai.alert")

  for _, assetKey in pairs(nest.bedAssets) do
    assetManager[assetKey]
      :setTranslation(0, -1.3, 0)
      :setRotation(0, 0, math.rad(90))
  end
end

nest.unload = function()
  nest.bgShader = nil
  nest.bgMesh = nil

  nest.bedButton.textFont = nil
  nest.bedButton.percentage = 0
  nest.bedButton.isHovered = false
end

nest.enter = function()
  nest.camera:setCurrent()
  local shader = g3d.shader
  shader:send("shadowRadiusX",  0.20)
  shader:send("shadowRadiusY",  0.06)
  shader:send("shadowSoftness", 0.7)
  shader:send("shadowStrength", 1.0)

  nest.hedgehog.x, nest.hedgehog.y = 0, 1.5
  nest.ball.z = 0 -- in case ball was kicked while leaving

  ai.timer = 1.0 -- bump timer for wander to happen sooner when character enters

  nest.bedButton.textFont = nil
  nest.bedButton.percentage = 0
  nest.bedButton.isHovered = false
  nest.bedButton.pulseTimer = 0

  -- Change musicKey in fadeOutMusic function too
  local musicKey = "audio.music.retroReggae"
  nest.music = audioManager.get(musicKey)
  nest.music:setLooping(true)
  nest.music:setVolume(0)
  nest.music:play()
  local targetVolume = audioManager.getVolume(musicKey)
  local fade = { t = 0 }
  flux.to(fade, 2, { t = 1 })
    :onupdate(function()
      nest.music:setVolume(targetVolume * fade.t)
    end)
end

nest.leave = function()
  require("src.player").camera:setCurrent()
  defaultShadowSettings()
  ai.resetState()

  nest.bedButton.textFont = nil
  nest.bedButton.percentage = 0
  nest.bedButton.isHovered = false
  nest.bedButton.pulseTimer = 0
end

nest.fadeOutMusic = function()
  if not nest.music then
    return
  end
  local currentVolume = nest.music:getVolume()
  if currentVolume == 0 then
    nest.music:stop()
    nest.music:setVolume(audioManager.getVolume("audio.music.retroReggae"))
    nest.must = nil
    return
  end
  local fade = { t = 1 }
  flux.to(fade, 2, { t = 0 })
    :onupdate(function()
      if nest.music then
        nest.music:setVolume(currentVolume * fade.t)
      end
    end)
    :oncomplete(function()
      if not nest.music then
        return
      end
      nest.music:stop()
      nest.music:setVolume(audioManager.getVolume("audio.music.retroReggae"))
      nest.music = nil
    end)
end

nest.setAspectRatio = function(aspectRatio)
  if not nest.camera then
    nest.load()
  end
  nest.camera.aspectRatio = aspectRatio
  nest.camera:updateProjectionMatrix()
end

nest.update = function(dt, scale)
  do -- background
    local expoMin, expoMax = 0.45, 0.8
    local offset = expoMin + (expoMax - expoMin) / 2.0
    local wave = math.sin(love.timer.getTime() * 0.33) * ((expoMax - expoMin) / 2)
    nest.bgShader:send("vignettePower", offset + wave)
  end

  if input.isGamepadActive() then
    local joyX, joyY = input.baton:get("target")
    if joyX ~= 0 and joyY ~= 0 then
      nest.camera:orbitalJoystick(joyX, joyY, dt)
    end
  end

  nest.ball:update(dt)

  nest.hedgehog:update(dt)
  -- move hedgehog after update
  ai.update(dt)

  local objectPositions = { }
  for _, object in ipairs(nest.objects) do
    table.insert(objectPositions, {
      object.x, object.y, object.z + 1e-3,
    })
  end

  local shader = g3d.shader
  local limit = math.min(#objectPositions, COLLECTABLE_SHADOW_MAX)
  if limit > 0 then
    shader:send("collectablePositions", unpack(objectPositions, 1, limit))
    shader:send("numCollectable", limit)
  else
    shader:send("numCollectable", 0)
  end

  if input.baton:pressed("pause") then
    ai.startBehaviour("play_ball", nest.ball)
  end

  local world = require("src.world") -- no sin is too far
  local cost = nest.bedLevels[nest.bedLevel + 1]
  if cost == nil then cost = math.huge end
  local canAfford = world.currencyLeaves >= cost

  -- bed button
  local noMoreBedUpgrades = nest.bedButton.cooldown < 0.3 and nest.bedLevel >= #nest.bedLevels
  if not noMoreBedUpgrades then
    local font = lg.getFont()
    local text = nest.bedButton.textFormatted
    if nest.bedButton.cooldown <= 0.31 then
      text = nest.bedButton.text:format(cost)
    end
    if not text then text = "it shouldn't reach here" end

    local buttonPadding = 10 * scale
    local buttonPaddingTop = 8 * scale

    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    local textX = math.floor(lg.getWidth() / 2 - textWidth / 2)
    local textY = buttonPaddingTop * 1.6 -- magic number sin

    nest.bedButton.textX, nest.bedButton.textY = textX, textY
    nest.bedButton.textFormatted = text
    nest.bedButton.textFont = font

    local buttonWidth = buttonPadding * 2 + textWidth
    local buttonHeight = textHeight + buttonPaddingTop

    local buttonX = math.floor(lg.getWidth() / 2 - buttonWidth / 2)
    local buttonY = buttonPadding

    nest.bedButton.buttonX, nest.bedButton.buttonY = buttonX, buttonY
    nest.bedButton.buttonWidth, nest.bedButton.buttonHeight = buttonWidth, buttonHeight

    -- Make text relational to buttons
    nest.bedButton.textX = nest.bedButton.textX - buttonX
    nest.bedButton.textY = nest.bedButton.textY - buttonY

    local mouseX, mouseY = love.mouse.getPosition()
    local wasHovered = nest.bedButton.isHovered
    nest.bedButton.isHovered = mouseX >= buttonX and mouseX <= buttonX + buttonWidth and
                      mouseY >= buttonY and mouseY <= buttonY + buttonHeight

    local isDisabled = not (nest.bedButton.disabled == 0 and nest.bedButton.cooldown == 0)

    if not isDisabled then
      if not wasHovered and nest.bedButton.isHovered then
        cursor.switch("hand")
      elseif wasHovered and not nest.bedButton.isHovered then
        cursor.switch("arrow")
      end
    else
      cursor.switch("arrow")
    end

    local previousPercentage = nest.bedButton.percentage
    local isInputDown = input.baton:down("bedPurchase") and ((input.isMouseActive() and nest.bedButton.isHovered) or input.isGamepadActive())

    if canAfford and isInputDown and not isDisabled then
      nest.bedButton.percentage = nest.bedButton.percentage + dt / 2.0 -- seconds until full
      if nest.bedButton.percentage > 1 then
        nest.bedButton.percentage = 1
      end
    elseif not canAfford and isInputDown and not isDisabled then
      nest.bedButton.disabled = nest.bedButton.disabledTime
      audioManager.play(SOUND_DISABLE)
    else
      nest.bedButton.percentage = nest.bedButton.percentage - dt / 0.8 -- seconds until empty
      if nest.bedButton.percentage < 0 then
        nest.bedButton.percentage = 0
      end
    end

    local currentPercentage = nest.bedButton.percentage
    local percentageChange = currentPercentage - previousPercentage
    local THRESHOLD = 1e-4

    if percentageChange > THRESHOLD then
      local pulseDelay = nest.bedButton.maxPulseDelay - (nest.bedButton.maxPulseDelay - nest.bedButton.minPulseDelay) * currentPercentage
      nest.bedButton.pulseTimer = nest.bedButton.pulseTimer + dt
      if nest.bedButton.pulseTimer >= pulseDelay then
        audioManager.play(SOUND_PULSE_CHARGE)
        nest.bedButton.pulseTimer = 0
      end
    elseif percentageChange < -THRESHOLD then
      local unwindDelay = 0.15
      nest.bedButton.pulseTimer = nest.bedButton.pulseTimer + dt
      if nest.bedButton.pulseTimer >= unwindDelay then
        audioManager.play(SOUND_PULSE_CHARGE)
        nest.bedButton.pulseTimer = 0
      end
    else
      nest.bedButton.pulseTimer = 0
    end
    
    if nest.bedButton.percentage == 1 then
      nest.bedButton.purchaseAnimationTime = nest.bedButton.animationTimeMax
      nest.bedButton.percentage = 0
      nest.bedButton.cooldown = nest.bedButton.animationTimeMax + nest.bedButton.cooldownTime

      if canAfford then
        world.currencyLeaves = world.currencyLeaves - cost
        nest.bedLevel = nest.bedLevel + 1
        flux.to(nest, 1, { bedVisualLevel = nest.bedLevel })
        if nest.bedLevel == 0 then -- Make the interaction available
          ai.addInteraction("interact.bed", 0, -1.3, 0.6, 0, -0.85, "interact.bed")
        end
        -- Tell ai to investigate change; since we're forcing them into the queue; do in opposite order of wanting to be ran in
        ai.triggerInteraction("interact.bed", true)
        ai.triggerScript("ai.alert", true)

        audioManager.play(SOUND_PURCHASE)
      end
    end

    nest.bedButton.purchaseAnimationTime = nest.bedButton.purchaseAnimationTime - dt
    if nest.bedButton.purchaseAnimationTime < 0 then
      nest.bedButton.purchaseAnimationTime = 0
    end
    nest.bedButton.cooldown = nest.bedButton.cooldown - dt
    if nest.bedButton.cooldown < 0 then
      cursor.switchIf(nest.bedButton.isHovered and not isDisabled, "hand")
      nest.bedButton.cooldown = 0
    end
    nest.bedButton.disabled = nest.bedButton.disabled - dt
    if nest.bedButton.disabled < 0 then
      cursor.switchIf(nest.bedButton.isHovered and not isDisabled, "hand")
      nest.bedButton.disabled = 0
    end
  end
  --

  if input.baton:pressed("reject") then
    nest.fadeOutMusic()
    ai.interrupt() -- we can't start our exit script, if ai is currently running one
    require("src.scripting").startScript("exit.pot")
    return
  end

end

nest.drawBed = function(level)
  level = level or 0

  local logicLevel = math.floor(level)
  local fractionalProgress = level - logicLevel

  for i = logicLevel, 0, -1 do
    local model = assetManager[nest.bedAssets[i]]
    model:setScale(1.0)
    model:draw()
  end

  if fractionalProgress > 0 and logicLevel + 1 <= #nest.bedAssets then
    local nextLevel = logicLevel + 1
    local model = assetManager[nest.bedAssets[nextLevel]]

    local currentScale = fractionalProgress
    local bounceFactor = 1.2
    if currentScale > 0.9 then
      currentScale = 1.0 + math.sin((currentScale - .9) * math.pi * bounceFactor) * 0.1
    end
    model:setScale(currentScale)
    model:draw()
  end
end

nest.draw = function()
  -- background
  lg.push("all")
    lg.origin()
    lg.setMeshCullMode("none")
    lg.setDepthMode("always", false)
    lg.setShader(nest.bgShader)
    lg.scale(lg.getDimensions())
    lg.draw(nest.bgMesh)
  lg.pop()
  lg.push("all")
    nest.camera:setCurrent()
    local interior = assetManager["model.nest.interior"]
    interior:setRotation(0, 0, math.rad(90))
      :draw()

    nest.drawBed(nest.bedVisualLevel)

    lg.setMeshCullMode("none")

    g3d.shader:send("disableLight", true)
    for _, object in ipairs(nest.objects) do
      object:draw()
    end
    g3d.shader:send("disableLight", false)

  lg.pop()
  lg.push("all")
    -- transparent draw last
    local lightShaft = assetManager["model.nest.interior.lightShaft"]
    lightShaft:setRotation(0, 0, math.rad(90))
    lg.setColor(1, 1, 1, 0.025)
    lightShaft:draw()
  lg.pop()
end

-- This is a cardinal sin, but game jams require sin to be committed to git
nest.drawUi = function(windowScale)
  if not nest.bedButton.textFont then
    return -- update loop hasn't ran
  end
  if nest.bedButton.cooldown < 0.3 and nest.bedLevel >= #nest.bedLevels then
    return
  end

  local color =  { .1, .1, .1 }
  if nest.bedButton.isHovered then
    color = { .2, .2, .2 }
  end

  local disabledT = 1 - nest.bedButton.disabled / nest.bedButton.disabledTime
  if disabledT > 0 then
    color[1] = (1 - disabledT) / 1.5
  end

  local font = nest.bedButton.textFont
  local textX, textY = nest.bedButton.textX, nest.bedButton.textY
  local text = nest.bedButton.textFormatted

  local buttonX, buttonY = nest.bedButton.buttonX, nest.bedButton.buttonY
  local buttonWidth, buttonHeight = nest.bedButton.buttonWidth, nest.bedButton.buttonHeight

  local percentage = nest.bedButton.percentage

  local scale, opacity = 1, 1
  local animT = 1 - nest.bedButton.purchaseAnimationTime / nest.bedButton.animationTimeMax
  if animT ~= 1.0 then
    scale = 1 + math.sin(animT + math.pi) * .2
    opacity = 1 - animT
  end

  local time = love.timer.getTime()
  local amp = percentage * nest.bedButton.wiggleMaxOffset
  local rotationalAmp = percentage * nest.bedButton.wiggleMaxRotation

  local offsetX = math.sin(time * nest.bedButton.wiggleSpeed) * amp
  local offsetY = math.sin(time * nest.bedButton.wiggleSpeed * 1.5) * amp

  local centreX, centreY = buttonWidth / 2, buttonHeight / 2
  local rotation = math.sin(time * nest.bedButton.wiggleSpeed) * rotationalAmp

  if disabledT ~= 1.0 then
    local remainingT = 1 - disabledT
    amp = amp + (nest.bedButton.wiggleMaxOffset * 3.0 * remainingT)
    rotationalAmp = rotationalAmp + (nest.bedButton.wiggleMaxRotation * 3.0 * remainingT)

    local eSpeed = nest.bedButton.wiggleSpeed * 1.5
    offsetX = math.sin(time * eSpeed) * amp
    offsetY = math.sin(time * eSpeed * 1.5) * amp
    rotation = math.sin(time * eSpeed) * rotationalAmp
  end

  if nest.bedButton.cooldown ~= 0 and nest.bedButton.cooldown < 0.3 then
    opacity = 1 - nest.bedButton.cooldown / 0.3
  end

  if nest.bedButton.cooldown == 0 or nest.bedButton.cooldown >= nest.bedButton.cooldownTime or nest.bedButton.cooldown < 0.3 then
    lg.push("all")
      lg.setStencilMode("draw", 1)
      lg.setColorMask(true)
      lg.translate(buttonX + offsetX, buttonY + offsetY)
      lg.translate(centreX, centreY)
      lg.rotate(rotation)
      lg.scale(scale)
      lg.translate(-centreX, -centreY)
      local r, g, b = unpack(color)
      lg.setColor(r, g, b, opacity)
      lg.rectangle("fill", 0, 0, buttonWidth, buttonHeight, 8 * windowScale)
      lg.setStencilMode("test", 1)
      lg.setColor(.08, .58, .08, 1, opacity) -- green
      lg.rectangle("fill", 0, 0, buttonWidth * percentage, buttonHeight)
      lg.setStencilMode("off")
      lg.setColor(1,1,1, opacity)
      lg.print(text, font, textX, textY)
    lg.pop()
  end
end

nest.mousemoved = function(scale, _, _, dx, dy, _)
  if dx ~= 0 and dy ~= 0 then
    if input.baton:down("unlockCamera") then
      nest.camera:orbitalLookAt(dx, dy, nil, nil, nil, nil, scale)
    end
  end
end

return nest