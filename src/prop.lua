local prop = { }
prop.__index = prop

prop.new = function(model, x, y, z, level, scale, collider)
  return setmetatable({
    model = model,
    x = x, y = y, z = z,
    level = level,
    scale = scale,
    collider = collider,
  }, prop)
end

prop.update = function(self, dt)

end

local lg = love.graphics
prop.draw = function(self)
  self.model:setTranslation(self.x, self.y, self.z + self.level.zLevel)
  self.model:setScale(self.scale)
  self.model:draw()
end

return prop