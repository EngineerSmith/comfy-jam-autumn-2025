local collectable = { }
collectable.__index = collectable

local logger = require("util.logger")
local assetManager = require("util.assetManager")
local audioManager = require("util.audioManager")

local g3d = require("libs.g3d")
local CUBE = g3d.newModel("scenes/game/cube.obj")

local zone = require("src.zone")
zone.collectableOrder = {
  "LEAF",
  "GOLDEN_LEAF",
}

local tags = {
  ["LEAF"] = {
    value = 1,
    rotationSpeed = math.rad(180), -- per second
    bobbingSpeed = 0.5, -- per second
    bobbingHeight = 0.5,
    bobbingOffset = 1,
    modelName = "model.collectable.leaf.1",
    audioName = "audio.fx.sweep_leaves",
    -- minimap
    radius = 1.5,
    activeColor = { .8, .5, .1, 1 },
    inactiveColor = { .3, .3, .05, 1 },
    draw = function(tag, collectable)
      tag.model:setTranslation(collectable:getPosition())
      tag.model:setRotation(0, 0, collectable.rotation)
      tag.model:setScale(collectable.scale * 0.5)
      tag.model:draw()
    end,
  },
  ["GOLDEN_LEAF"] = {
    value = 10,
    rotationSpeed = math.rad(120), -- per second
    bobbingSpeed = 1.0, -- per second
    bobbingHeight = 0.5,
    bobbingOffset = 1,
    modelName = "model.collectable.leaf.gold",
    audioName = "audio.fx.collect_special",
    -- minimap
    radius = 2,
    activeColor = { .8, .8, 0, 1 },
    inactiveColor = { .5, .5, .1, 1 },
    draw = function(tag, collectable)
      tag.model:setTranslation(collectable:getPosition())
      tag.model:setRotation(0, 0, collectable.rotation)
      tag.model:setScale(collectable.scale * 0.5)
      tag.model:draw()
    end,
  }
}

local tagAssets, lookup = { }, { }
for _, tag in pairs(tags) do
  if type(tag.modelName) == "string" and not lookup[tag.modelName] then
    table.insert(tagAssets, tag.modelName)
    lookup[tag.modelName] = true
  end
  if type(tag.audioName) == "string" and not lookup[tag.audioName] then
    table.insert(tagAssets, tag.audioName)
    lookup[tag.modelName] = true
  end
end
lookup = nil

collectable.getAssetList = function()
  return tagAssets
end

collectable.load = function()
  for _, tag in pairs(tags) do
    if type(tag.modelName) == "string" then
      local model = assetManager[tag.modelName]
      if not model then
        logger.warn("Couldn't find collectable model with ID:", tag.modelName, ". Attempting to continue with CUBE")
        tag.model = CUBE
      else
        tag.model = model
      end
    end
  end
end

collectable.unload = function()
  for _, tag in pairs(tags) do
    tag.model = nil
  end
end

collectable.getTag = function(tag)
  if type(tag) == "table" then
    tag = tag.tag -- if self is passed in
  end
  return tags[tag]
end

collectable.new = function(x, y, level, tag, zoneName, zOffset)
  local self = setmetatable({
    x = x or 0, y = y or 0, z = level.zLevel,
    level = level,
    tag = tag,
    zone = zoneName or "unknown",
    scale = 1,
    rotation = 0,
    zOffset = zOffset or 0,
    zBob = 0,
  }, collectable)

  zone.addCollectable(self.zone, self.tag)

  return self
end

collectable.getPosition = function(self)
  return self.x, self.y, self.z + self.zOffset + self.zBob
end

collectable.getShadowPosition = function(self)
  return self.x, self.y, self.z + self.zOffset
end

collectable.getRadius = function(self)
  local tag = self:getTag()
  return tag.radius or 1
end

collectable.update = function(self, dt)
  if self.isCollected then
    return -- don't update non-rendering collectables
  end

  local tag = self:getTag()

  self.rotation = self.rotation + (tag.rotationSpeed or math.rad(90)) * dt
  self.zBob = math.sin(love.timer.getTime() * (tag.bobbingSpeed or 2)) * (tag.bobbingHeight or 2) + (tag.bobbingOffset or 0)
end

collectable.collected = function(self)
  self.isCollected = true
  self.scale = 1
  local tag = self:getTag()
  if tag.audioName then
    audioManager.play(tag.audioName)
  end

  zone.setCollected(self.zone, self.tag)

  return tag.value
end

local lg = love.graphics
collectable.debugDraw = function(self)
  lg.push("all")
  local tag = self:getTag()
  lg.setColor(tag.activeColor or { .4, .8, .4, 1 })
  if self.isCollected then
    lg.setColor(tag.inactiveColor or { .1, .4, .1, 1 })
  end
  lg.translate(self.x, self.y)
  lg.rotate(math.rad(-90)+love.timer.getTime()/2)
  lg.circle("fill", 0, 0, tag.radius, 3)
  lg.pop()
end

collectable.draw = function(self)
  if self.isCollected then
    return
  end

  local tag = self:getTag()
  if tag and tag.draw then
    tag.draw(tag, self)
  end
end

return collectable