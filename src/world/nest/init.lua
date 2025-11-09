local nest = { }

local lg = love.graphics

local g3d = require("libs.g3d")

local input = require("util.input")
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

nest.load = function()
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
end

nest.leave = function()
  require("src.player").camera:setCurrent()
  defaultShadowSettings()
  ai.resetState()
end

nest.setAspectRatio = function(aspectRatio)
  if not nest.camera then
    nest.load()
  end
  nest.camera.aspectRatio = aspectRatio
  nest.camera:updateProjectionMatrix()
end

nest.update = function(dt)
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

    nest.drawBed(4)

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

nest.mousemoved = function(scale, _, _, dx, dy, _)
  if dx ~= 0 and dy ~= 0 then
    if input.baton:down("unlockCamera") then
      nest.camera:orbitalLookAt(dx, dy, nil, nil, nil, nil, scale)
    end
  end
end

return nest