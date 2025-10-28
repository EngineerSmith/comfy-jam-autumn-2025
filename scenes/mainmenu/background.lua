local background = { }

local lg = love.graphics

local assetManager = require("util.assetManager")

background.load = function()
  background.sprites = {
    assetManager["sprite.leaves.1"],
  }
end

background.unload = function()
  background.sprites = nil
  background.leaves = nil
  background.gradientMesh = nil
end

local TOP_COLOR = { 115/255, 61/255, 26/255, 1 } -- Deep Ochre
local BOTTOM_COLOR = { 60/255, 30/255, 10/255, 1 } -- Richer brown
local createGradientMesh = function(w, h)
  local vertices = {
    { 0, 0, 0, 0, unpack(TOP_COLOR) },
    { 0, h, 0, 0, unpack(BOTTOM_COLOR) },
    { w, h, 0, 0, unpack(BOTTOM_COLOR) },
    
    { 0, 0, 0, 0, unpack(TOP_COLOR) },
    { w, h, 0, 0, unpack(BOTTOM_COLOR) },
    { w, 0, 0, 0, unpack(TOP_COLOR) },
  }
  background.gradientMesh = lg.newMesh(vertices, "triangles", "static")
end

background.resize = function(w, h, scale)
  createGradientMesh(w, h)

  background.leaves = { }
  for _ = 1, 10 + 30 * scale do
    local spriteIndex = love.math.random(#background.sprites)
    local sprite = background.sprites[spriteIndex]
    local sWidth, sHeight = sprite:getDimensions()
    local scaledWidth, scaledHeight = sWidth * scale, sHeight * scale

    local initX = love.math.random(-scaledWidth, w + scaledWidth)
    local initY = love.math.random(-scaledHeight, h + scaledHeight) + love.math.random()

    table.insert(background.leaves, {
      x = initX, baseX = initX,
      y = initY,
      sprite = spriteIndex,

      waveTimeOffset = love.math.random() * 2 * math.pi, -- Phase offset for sine wave
      flutterAmplitude = (love.math.random() * .4 + .6) * 15 * scale, -- Max swing
      flutterFrequency = love.math.random() * .6 + .3, -- Speed of side-to-side swing

      rotation = love.math.random() * 2 * math.pi,
      rotationSpeed = (love.math.random() - .5) * .4,
      rotationWaveFrequency = love.math.random() * 1.5 + .8, -- Speed of rotational wobble
      rotationAmplitude = math.pi / (love.math.random(6) + 6),

      fallSpeed = 30 * scale + love.math.random() * 20 * scale,
    })
  end
end

local getProximityValue = function(mag, radius, power)
  if mag <= 0 then
    return 1.0
  end

  local normalizedMag = math.min(mag / radius, 1.0)
  return math.pow(1 - normalizedMag, power)
end

background.update = function(dt, scale)
  local currentTime = love.timer.getTime()

  local lgWidth, lgHeight = lg.getDimensions()
  local mouseX, mouseY = love.mouse.getPosition()

  for _, leaf in ipairs(background.leaves) do
    local sprite = background.sprites[leaf.sprite]
    local sWidth, sHeight = sprite:getDimensions()
    local scaledWidth, scaledHeight = sWidth * scale, sHeight * scale
    local halfWidth, halfHeight = scaledWidth / 2, scaledHeight / 2

    -- Mouse repulsion logic
    local centerX, centreY = leaf.baseX + halfWidth, leaf.y + halfHeight
    local dx, dy = mouseX - centerX, mouseY - centreY

    local mag = math.sqrt(dx * dx + dy * dy)
    local proximity = getProximityValue(mag, 100 * scale, 2)

    if proximity > 0 then
      local dirX, dirY = dx / mag, dy / mag
      local force = (60 * scale) * proximity * dt
      leaf.baseX = leaf.baseX + -dirX * force
      leaf.y = leaf.y + -dirY * force
    end

    -- Falling motion
    leaf.y = leaf.y + leaf.fallSpeed * dt

    -- Horizontal Flutter
    local flutterOffset = leaf.flutterAmplitude * math.sin(currentTime * leaf.flutterFrequency + leaf.waveTimeOffset)
    leaf.x = leaf.baseX + flutterOffset

    -- Rotation Motion
    local rotationWobble = leaf.rotationAmplitude * math.cos(currentTime * leaf.rotationWaveFrequency + leaf.waveTimeOffset)
    leaf.rotation = leaf.rotation + (leaf.rotationSpeed * rotationWobble) * dt

    -- Wrap around screen
    if leaf.y > lgHeight then
      leaf.y = leaf.y - lgHeight - scaledHeight
      leaf.baseX = love.math.random(-scaledWidth / 2, lgWidth + scaledWidth / 2)
      leaf.x = leaf.baseX
      leaf.waveTimeOffset = love.math.random() * 2 * math.pi
    end
  end
end

background.draw = function(scale)
  local limitedScale = math.max(1, scale * .95)

  lg.push("all")
    lg.setColor(1, 1, 1, 1)
    lg.draw(background.gradientMesh)

    for _, leaf in ipairs(background.leaves) do
      local sprite = background.sprites[leaf.sprite]
      local sWidth, sHeight = sprite:getDimensions()
      local originX, originY = sWidth / 2, sHeight / 2

      lg.draw(sprite,
        math.floor(leaf.x + originX * limitedScale),
        math.floor(leaf.y + originY * limitedScale),
        leaf.rotation,
        limitedScale, limitedScale,
        originX, originY
      )
    end
  lg.pop()
end

return background