local colliderCircle = { }
colliderCircle.__index = colliderCircle

local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")


colliderCircle.new = function(x, y, radius, segments, tag, levels)
  if type(tag) == "string" then
    tag = slickHelper.tags[tag]
  end

  local shape = slick.newCircleShape(0, 0, radius, segments, tag)
  local self = setmetatable({
      shape = shape,
      levels = levels,
      x = x, y = y, radius = radius, segments = segments,
    }, colliderCircle)

  for _, level in ipairs(levels) do
    level:add(self, x, y, self.shape)
  end

  return self
end

colliderCircle.remove = function(self)
  for _, level in ipairs(self.levels) do
    level:remove(self)
  end
  self.levels = nil
end

local lg = love.graphics
colliderCircle.draw = function(self)
  lg.push("all")
  lg.setColor(0,1,1,0.5)
  lg.circle("fill", self.x, self.y, self.radius, self.segments)
  lg.pop()
end

return colliderCircle