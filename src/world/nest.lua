local nest = { }

local lg = love.graphics

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
end

nest.unload = function()
  nest.bgShader = nil
  nest.bgMesh = nil
end

nest.update = function(dt)
  -- background
  do
    local expoMin, expoMax = 0.45, 0.8
    local offset = expoMin + (expoMax - expoMin) / 2.0
    local wave = math.sin(love.timer.getTime() * 0.33) * ((expoMax - expoMin) / 2)
    nest.bgShader:send("vignettePower", offset + wave)
  end
end

nest.draw = function()
  -- background
  lg.push("all")
    lg.origin()
    lg.setMeshCullMode("none")
    lg.setShader(nest.bgShader)
    lg.scale(lg.getDimensions())
    lg.draw(nest.bgMesh)
  lg.pop()
end

return nest