local prop = { }
prop.__index = prop

prop.new = function(model, texture, x, y, z, level, scale, collider)
  return setmetatable({
    model = model,
    texture = texture,
    x = x or 0, y = y or 0, z = z or 0,
    level = level,
    scale = scale,
    collider = collider,
    rx = 0, ry = 0, rz = 0,
  }, prop)
end

prop.setRotation = function(self, rx, ry, rz)
  self.rx, self.ry, self.rz = rx or 0, ry or 0, rz or 0

  if self.collider then
    self.collider:rotate(self.rz)
  end
end

prop.setNoScaleZ = function(self, bool)
  self.noScaleZ = bool == true
end

prop.update = function(self, dt)

end

local lg = love.graphics
prop.draw = function(self)
  self.model:setTexture(self.texture)
  self.model:setTranslation(self.x, self.y, self.z + self.level.zLevel)
  local preRX, preRY, preRZ = self.model.rotation[1], self.model.rotation[2], self.model.rotation[3]
  self.model:setRotation(preRX + self.rx, preRY + self.ry, preRZ + self.rz)
  if self.noScaleZ then
    if preRX ~= 0 then
      self.model:setScale(self.scale, 1, self.scale)
    else
      self.model:setScale(self.scale, self.scale, 1)
    end
  else
    self.model:setScale(self.scale)
  end
  self.model:draw()
  self.model:setRotation(preRX, preRY, preRZ)
end

return prop