local collectable = { }
collectable.__index = collectable

local logger = require("util.logger")
local assetManager = require("util.assetManager")

local g3d = require("libs.g3d")
local CUBE = g3d.newModel("scenes/game/cube.obj")

local tags = {
  ["LEAF"] = {
    radius = 2, -- for minimap
    rotationSpeed = math.rad(180), -- per second
    bobbingSpeed = 0.5, -- per second
    bobbingHeight = 0.5,
    bobbingOffset = 1,
    modelName = "model.collectable.leaf.1",
    draw = function(tag, collectable)
      tag.model:setTranslation(collectable:getPosition())
      tag.model:setRotation(0, 0, collectable.rotation)
      tag.model:setScale(collectable.scale * 0.5)
      tag.model:draw()
    end,
  }
}

local tagModels = { }
for _, tag in pairs(tags) do
  if type(tag.modelName) == "string" then
    table.insert(tagModels, tag.modelName)
  end
end

collectable.getModelList = function()
  return tagModels
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

collectable.new = function(x, y, level, tag)
  return setmetatable({
    x = x or 0, y = y or 0, z = level.zLevel,
    level = level,
    tag = tag,
    scale = 1,
    rotation = 0,
    zOffset = 0,
  }, collectable)
end

collectable.getPosition = function(self)
  return self.x, self.y, self.z + self.zOffset
end

collectable.getShadowPosition = function(self)
  return self.x, self.y, self.z
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
  self.zOffset = math.sin(love.timer.getTime() * (tag.bobbingSpeed or 2)) * (tag.bobbingHeight or 2) + (tag.bobbingOffset or 0)
end

collectable.collected = function(self)
  self.isCollected = true
  self.scale = 1
end

local lg = love.graphics
collectable.debugDraw = function(self)
  lg.push("all")
  lg.setColor(1,1,0, 1)
  if self.isCollected then
    lg.setColor(.5,.5,0,1)
  end
  lg.translate(self.x, self.y)
  lg.rotate(math.rad(-90)+love.timer.getTime()/2)
  local tag = self:getTag()
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