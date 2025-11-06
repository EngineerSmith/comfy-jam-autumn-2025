local background = { }

local lg = love.graphics

local assetManager = require("util.assetManager")

background.load = function()
  background.sprites = {
    assetManager["sprite.leaves.1"],
  }
  background.trees = {
    {
      x = 0.2,
      sprite = assetManager["sprite.trees.1"],
    },
    {
      x = 0.95,
      sprite = assetManager["sprite.trees.1"],
    },
    {
      x = 0.7,
      sprite = assetManager["sprite.trees.2"],
    },
  }
  background.treeShader = lg.newShader(
[[
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
  vec4 textureColor = Texel(tex, texture_coords);
  if (textureColor.a - 0.05 <= 0.0)
    discard;
  return textureColor * color;
}
]])
end

background.unload = function()
  background.sprites = nil
  background.leaves = nil
  background.gradientMesh = nil
  background.gradientTreeMesh = nil
  background.treeShader = nil
end

-- local TOP_COLOR = { 115/255, 61/255, 26/255, 1 } -- Deep Ochre
-- local BOTTOM_COLOR = { 60/255, 30/255, 10/255, 1 } -- Richer brown
local TOP_COLOR = { 107/255, 60/255, 31/255, 1 }
local BOTTOM_COLOR = { 69/255, 39/255, 21/255, 1 }
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

-- local TOP_TREE_COLOR = { 95/255, 50/255, 22/255, 1 }
-- local BOTTOM_TREE_COLOR = { 70/255, 37/255, 12/255, 1 }
local TOP_TREE_COLOR = { 85/255, 48/255, 25/255, 1 }
local BOTTOM_TREE_COLOR = { 54/255, 31/255, 17/255, 1 }
local createGradientTreeMesh = function(w, h)
  local vertices = {
    { 0, 0, 0, 0, unpack(TOP_TREE_COLOR) },
    { 0, h, 0, 0, unpack(BOTTOM_TREE_COLOR) },
    { w, h, 0, 0, unpack(BOTTOM_TREE_COLOR) },
    
    { 0, 0, 0, 0, unpack(TOP_TREE_COLOR) },
    { w, h, 0, 0, unpack(BOTTOM_TREE_COLOR) },
    { w, 0, 0, 0, unpack(TOP_TREE_COLOR) },
  }
  background.gradientTreeMesh = lg.newMesh(vertices, "triangles", "static")
end

background.resize = function(w, h, scale)
  createGradientMesh(w, h)
  createGradientTreeMesh(w, h)

  background.leaves = { }
  for _ = 1, 10 + 30 * scale do
    local spriteIndex = love.math.random(#background.sprites)
    local sprite = background.sprites[spriteIndex]
    local sWidth, sHeight = sprite:getDimensions()
    local scaledWidth, scaledHeight = sWidth * scale, sHeight * scale

    local initX = love.math.random(-scaledWidth, w + scaledWidth)
    local initY = love.math.random(-scaledHeight, h + scaledHeight) + love.math.random()

    local color = love.math.random(70, 100) / 100

    table.insert(background.leaves, {
      x = initX, baseX = initX,
      y = initY,
      sprite = spriteIndex,

      color = color,

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

    lg.push("all")
    lg.setStencilMode("draw", 1)
    lg.setColorMask(true)
    lg.setShader(background.treeShader)
    for _, tree in ipairs(background.trees) do
      local s = 0.5*scale
      local sWidth, sHeight = tree.sprite:getDimensions()
      lg.draw(tree.sprite, lg.getWidth()*tree.x-sWidth/2*s, lg.getHeight()-sHeight*s, 0, s)
    end
    lg.setShader(nil)
    lg.setStencilMode("test", 1)
    lg.draw(background.gradientTreeMesh)
    lg.setStencilMode("off")
    lg.pop()

    for _, leaf in ipairs(background.leaves) do
      local sprite = background.sprites[leaf.sprite]
      local sWidth, sHeight = sprite:getDimensions()
      local originX, originY = sWidth / 2, sHeight / 2

      lg.setColor(leaf.color, leaf.color, leaf.color, 1)
      lg.draw(sprite,
        math.floor(leaf.x + originX * limitedScale),
        math.floor(leaf.y + originY * limitedScale),
        leaf.rotation,
        limitedScale, limitedScale,
        originX, originY
      )
    end
  lg.setColor(1,1,1,1)
  lg.pop()
end

return background