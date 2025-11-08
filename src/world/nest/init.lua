local nest = { }

local lg = love.graphics

local g3d = require("libs.g3d")

local input = require("util.input")
local assetManager = require("util.assetManager")

local object = require("src.world.nest.object")

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

  nest.objects = {
    nest.hedgehog,
  }
end

nest.unload = function()
  nest.bgShader = nil
  nest.bgMesh = nil
end

nest.enter = function()
  nest.camera:setCurrent()
  local shader = g3d.shader
  shader:send("shadowRadiusX",  0.25)
  shader:send("shadowRadiusY",  0.06)
  shader:send("shadowSoftness", 0.7)
  shader:send("shadowStrength", 1.0)

  nest.hedgehog.x, nest.hedgehog.y = 0, 1.7
end

nest.leave = function()
  require("src.player").camera:setCurrent()
  defaultShadowSettings()
end

nest.setAspectRatio = function(aspectRatio)
  if not nest.camera then
    nest.load()
  end
  nest.camera.aspectRatio = aspectRatio
  nest.camera:updateProjectionMatrix()
end

local timer = 0
local toX, toY = 0, 0
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

  nest.hedgehog:update(dt)
  -- move hedgehog after update
  timer = timer - dt
  if timer <= 0  then
    local radius = love.math.random(-15, 15) / 10
    local ang = love.math.random() * 2 * math.pi
    toX, toY = radius * math.cos(ang), radius * math.sin(ang)
    timer = 5.0
  end

  local dx, dy = toX - nest.hedgehog.x, toY - nest.hedgehog.y
  local mag = math.sqrt(dx * dx + dy * dy)
  if mag >= 0.1 then
    nest.hedgehog:move(dx / mag * dt, dy / mag * dt)
  end

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

  if input.baton:pressed("reject") then
    require("src.scripting").startScript("exit.pot")
    return
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
    interior:draw()

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

nest.mousemoved = function(_, _, dx, dy, _)
  if dx ~= 0 and dy ~= 0 then
    if input.baton:down("unlockCamera") then
      nest.camera:orbitalLookAt(dx, dy)
    end
  end
end

return nest