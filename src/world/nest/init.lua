local nest = { }

local lg = love.graphics

local g3d = require("libs.g3d")

local input = require("util.input")
local cursor = require("util.cursor")
local assetManager = require("util.assetManager")

local ai = require("src.world.nest.ai")
local object = require("src.world.nest.object")

nest.bedAssets = {
  [0] = "model.nest.interior.bed.0",
  [1] = "model.nest.interior.bed.1",
  [2] = "model.nest.interior.bed.2",
  [3] = "model.nest.interior.bed.3",
  [4] = "model.nest.interior.bed.4",
}

nest.bedLevels = {
  [0] = 5,
  [1] = 0,
  [2] = 0,
  [3] = 0,
  [4] = 0,
}

nest.bedButton = {
  text = "Upgrade Bed: %d leaves",
  percentage = 0,
  isHovered = false,
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

nest.load = function()
  nest.bedLevel = -1 -- cutscene raises bedLevel to 0

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
  local tex = assetManager["sprite.hedgehog.idle"]
  nest.hedgehog:setStateTexture("idle", tex, 1, 0)
  local tex = assetManager["sprite.hedgehog.walking"]
  nest.hedgehog:setStateTexture("walking", tex, 2, 0.1)

  nest.ball = object.new()
  local tex = assetManager["sprite.ball.idle"]
  nest.ball:setStateTexture("idle", tex, 1, 0)
  local tex = assetManager["sprite.ball.walking"]
  nest.ball:setStateTexture("walking", tex, 3, 0.2)

  nest.objects = {
    nest.hedgehog,
    nest.ball,
  }

  ai.addCharacterControl(nest.hedgehog)

  -- I want all bed's to share a matrix, share with level 0 for simplicity
  local sourceMatrix = assetManager[nest.bedAssets[0]]
      :setTranslation(0, -1.3, 0)
      :setRotation(0, 0, math.rad(90))
      .matrix
  for index, assetKey in pairs(nest.bedAssets) do
    if index ~= 0 then
      local model = assetManager[assetKey]
      model.matrix = sourceMatrix
    end
  end
  ai.addInteraction("interact.bed", 0, -1.3, 0.6, 0, -0.85, "interact.bed")
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
  nest.ball.x, nest.ball.y = 1.2, -.4

  ai.timer = 1.0 -- bump timer for wander to happen sooner when character enters

  nest.bedButton.textFont = nil
  nest.bedButton.percentage = 0
  nest.bedButton.isHovered = false
end

nest.leave = function()
  require("src.player").camera:setCurrent()
  defaultShadowSettings()
  ai.resetState()

  nest.bedButton.textFont = nil
  nest.bedButton.percentage = 0
  nest.bedButton.isHovered = false
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

    local bool = input.baton:down("bedPurchase") and ((input.isMouseActive() and nest.bedButton.isHovered) or input.isGamepadActive())

    if canAfford and bool and not isDisabled then
      nest.bedButton.percentage = nest.bedButton.percentage + dt / 2.0 -- seconds until full
      if nest.bedButton.percentage > 1 then
        nest.bedButton.percentage = 1
      end
    elseif not canAfford and bool and not isDisabled then
      nest.bedButton.disabled = nest.bedButton.disabledTime
    else
      nest.bedButton.percentage = nest.bedButton.percentage - dt / 0.8 -- seconds until empty
      if nest.bedButton.percentage < 0 then
        nest.bedButton.percentage = 0
      end
    end
    
    if nest.bedButton.percentage == 1 then
      nest.bedButton.purchaseAnimationTime = nest.bedButton.animationTimeMax
      nest.bedButton.percentage = 0
      nest.bedButton.cooldown = nest.bedButton.animationTimeMax + nest.bedButton.cooldownTime

      if canAfford then
        world.currencyLeaves = world.currencyLeaves - cost
        nest.bedLevel = nest.bedLevel + 1
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
    ai.interrupt() -- we can't start our exit script, if ai is currently running one
    require("src.scripting").startScript("exit.pot")
    return
  end

end

nest.drawBed = function(level)
  level = level or 0
  for i = level, 0, -1 do
    local model = assetManager[nest.bedAssets[i]]
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

    nest.drawBed(nest.bedLevel)

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
nest.drawUi = function(scale)
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
      lg.rectangle("fill", 0, 0, buttonWidth, buttonHeight, 16)
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