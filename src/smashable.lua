local smashable = { }
smashable.__index = smashable

local g3d = require("libs.g3d")
local flux = require("libs.flux")
local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

local logger = require("util.logger")
local audioManager = require("util.audioManager")
local assetManager = require("util.assetManager")

local CUBE = g3d.newModel("scenes/game/cube.obj")

local tags = {
  ["POT"] = {
    modelName = "model.flower_pot.small",
    audioName = "audio.fx.hit.pot",
    scale = 3,
    radius = 0.1, -- model radius
    -- debug draws
    color = { .2, .8, .2, 1 },
    --
    draw = function(tag, smashable)
      local scale = smashable.scale * tag.scale
      local x, y, z = smashable:getPosition()
      tag.model:setTranslation(x, y, z + 0.268 * scale)
      local preRX, preRY, preRZ = tag.model.rotation[1], tag.model.rotation[2], tag.model.rotation[3]
      tag.model:setRotation(preRX, preRY + math.rad(180), preRZ + smashable.rotation)
      tag.model:setScale(scale)
      tag.model:draw()
      tag.model:setRotation(preRX, preRY, preRZ)
    end,
  }
}
tags.POT.shape = slickHelper.rotateShapeVertices(slick.newCircleShape(0, 0, tags.POT.radius * tags.POT.scale, 6, slickHelper.tags.SMASHABLE_POT), math.rad(90), 0, 0)

local tagAssets, lookup = { }, { }
for _, tag in pairs(tags) do
  if type(tag.modelName) == "string" and not lookup[tag.modelName] then
    lookup[tag.modelName] = true
    table.insert(tagAssets, tag.modelName)
  end
  if type(tag.audioName) == "string" and not lookup[tag.audioName] then
    lookup[tag.audioName] = true
    table.insert(tagAssets, tag.audioName)
  end
end
lookup = nil

smashable.getAssetList = function()
  return tagAssets
end

smashable.load = function()
  for _, tag in pairs(tags) do
    if type(tag.modelName) == "string" then
      local model = assetManager[tag.modelName]
      if not model then
        logger.warn("Couldn't find smashable model with ID:", tag.modelName, ". Attempting to continue with cube.")
        tag.model = CUBE
      else
        tag.model = model
      end
    end
  end
end

smashable.unload = function()
  for _, tag in pairs(tags) do
    tag.model = nil
  end
end

smashable.getTag = function(tag)
  if type(tag) == "table" then
    tag = tag.tag
  end
  return tags[tag]
end

smashable.new = function(x, y, level, tag, zOffset)
  local self = setmetatable({
    x = x or 0,
    y = y or 0,
    z = level.zLevel,
    tag = tag,
    level = level,
    zOffset = zOffset or 0,
    scale = 1,
    rotation = 0,
    litter = { },
  }, smashable)
  self.zOffset = self.zOffset + 0.1
  self.level:add(self, self.x, self.y, self:getTag().shape)
  return self
end

smashable.getPosition = function(self)
  return self.x ,self.y, self.z + self.zOffset
end

smashable.smashed = function(self)
  if not self.level then
    return
  end
  self.level:remove(self)
  self.level = nil
  self.isSmashed = true
  local tag = self:getTag()
  if tag.audioName then
    audioManager.play(tag.audioName, 2.0)
  end

  local x, y, z = self:getPosition()
  for i = 0, love.math.random(3,5) do
    local litter = {
      x = x, y = y, z = z,
      rx = 0, ry = 0, rz = 0,
      opacity = 1.0,
    }
    table.insert(self.litter, litter)

    local popHeight = 0.5 + love.math.random() * 0.5
    local fallDuration = 0.3
    local popDuration = (0.5 + love.math.random() * 0.3) - fallDuration

    local angle = love.math.random() * 2 * math.pi
    local dist = 0.5 + love.math.random() * 0.8 -- how far it flies
    local targetX = x + math.cos(angle) * dist
    local targetY = y + math.sin(angle) * dist

    flux.to(litter, popDuration, {
        x = targetX, y = targetY, z = z + popHeight,
        rx = love.math.random() * 4 * math.pi,
        ry = love.math.random() * 4 * math.pi,
        rz = love.math.random() * 4 * math.pi,
      })
      :ease("cubicout")
      :after(fallDuration, {
        z = z - 1.0,
        opacity = 0.0,
      })
      :ease("cubicin")
      :oncomplete(function()
        for i, l in ipairs(self.litter) do
          if l == litter then
            table.remove(self.litter, i)
            break
          end
        end
      end)
  end
end

local lg = love.graphics
smashable.debugDraw = function(self)
  lg.push("all")
  local tag = self:getTag()
  lg.setColor(tag.color or { .2, .8, .2, 1})
  lg.translate(self.x, self.y)
  lg.circle("fill", 0, 0, (tag.radius or 1) * self.scale * tag.scale, 6)
  lg.pop()
end

smashable.draw = function(self)
  local tag = self:getTag()
  if self.isSmashed then
    -- draw litter cubes
    lg.push("all")
    for _, litter in ipairs(self.litter) do
      lg.setColor(1, 1, 1, litter.opacity)
      CUBE:setTranslation(litter.x, litter.y, litter.z)
      CUBE:setRotation(litter.rx, litter.ry, litter.rz)
      CUBE:setScale((((tag.radius or 1) * self.scale * tag.scale) / 2)) -- 1/2 the scale of the smashable model, 0.25 for the size of the cube
      CUBE:draw()
    end
    lg.pop()
    return
  end

  if tag and tag.draw then
    tag:draw(self)
  end
end

return smashable