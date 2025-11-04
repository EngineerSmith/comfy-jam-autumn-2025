local colliderCircle = { }
colliderCircle.__index = colliderCircle

local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")


colliderCircle.new = function(x, y, radius, segments, rotation, tag, levels)
  if type(tag) == "string" then
    tag = slickHelper.tags[tag]
  end

  local shape = slick.newCircleShape(0, 0, radius, segments, tag)
  local self = setmetatable({
      shape = shape,
      levels = levels,
      x = x, y = y, 
      radius = radius, segments = segments,
      rotation = 0,
    }, colliderCircle)

  for _, level in ipairs(self.levels) do
    level:add(self, x, y, self.shape)
  end

  self:rotate(rotation or 0)

  return self
end

colliderCircle.remove = function(self)
  for _, level in ipairs(self.levels) do
    level:remove(self)
  end
  self.levels = nil
end

colliderCircle.rotate = function(self, rz)
  if rz == 0 then
    return
  end

  self.rotation = self.rotation + rz

  local trans = slick.newTransform(self.x, self.y, self.rotation)

  for _, level in ipairs(self.levels) do
    level.world:update(self, trans)
  end
end

local lg = love.graphics
colliderCircle.debugDraw = function(self)
  lg.push("all")
  lg.setColor(0,0,1,0.5)
  lg.translate(self.x, self.y)
  lg.rotate(self.rotation)
  lg.circle("fill", 0, 0, self.radius, self.segments)
  lg.pop()
end

return colliderCircle