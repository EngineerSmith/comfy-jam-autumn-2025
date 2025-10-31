local colliderRectangle = { }
colliderRectangle.__index = colliderRectangle

local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

colliderRectangle.new = function(x, y, width, height, tag, levels)
  if type(tag) == "string" then
    tag = slickHelper.tags[tag]
  end

  local shape = slick.newRectangleShape(0, 0, width, height, tag)
  local self = setmetatable({
      shape = shape,
      levels = levels,
      x = x, y = y, width = width, height = height,
    }, colliderRectangle)

  for _, level in ipairs(levels) do
    level:add(self, x, y, self.shape)
  end

  return self
end

colliderRectangle.remove = function(self)
  for _, level in ipairs(self.levels) do
    level:remove(self)
  end
  self.levels = nil
end

local lg = love.graphics
colliderRectangle.draw = function(self)
  lg.push("all")
  lg.setColor(0,1,1,0.5)
  lg.rectangle("fill", self.x, self.y, self.width, self.height)
  lg.pop()
end

return colliderRectangle