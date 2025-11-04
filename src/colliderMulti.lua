local colliderMulti = { }
colliderMulti.__index = colliderMulti

local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

colliderMulti.new = function(x, y, scale, shapes, tag, levels)
  if type(tag) == "string" then
    tag = slickHelper.tags[tag]
  end

  scale = scale or 1

  local varargs, debugShapes = { }, { }
  for i, s in ipairs(shapes) do
    local shape, debugShape
    if s.shape == "circle" then
      local x, y, radius = (s.x or 0) * scale, (s.y or 0) * scale, (s.radius or 1) * scale
      shape = slick.newCircleShape(x, y, radius, s.segments, tag)
      debugShape = { shape = "circle", x = x, y = y, radius = radius, segments = s.segments }
    elseif s.shape == "rectangle" then
      local x, y, width, height = (s.x or 0) * scale, (s.y or 0) * scale, (s.width or 1) * scale, (s.height or 1) * scale
      shape = slick.newRectangleShape(x, y, width, height, tag)
      debugShape = { shape = "rectangle", x = x, y = y, width = width, height = height }
    else
      logger.warn("Invalid shape given to multi-shape["..tostring(i).."]: '"..tostring(s.shape).."'. Check spelling. Ignoring index.")
    end
    if shape then table.insert(varargs, shape) end
    if debugShape then table.insert(debugShapes, debugShape) end
  end

  if tag then
    table.insert(varargs, tag)
  end
  local shapeGroup = slick.newShapeGroup(unpack(varargs))
  local self = setmetatable({
    shape = shapeGroup,
    levels = levels,
    x = x, y = y,
    debugShapes = debugShapes,
    rotation = 0,
  }, colliderMulti)

  for _, level in ipairs(self.levels) do
    level:add(self, self.x, self.y, self.shape)
  end

  self:rotate(rotation or 0)

  return self
end

colliderMulti.remove = function(self)
  for _, level in ipairs(self.levels) do
    level:remove(self)
  end
  self.levels = nil
end

colliderMulti.rotate = function(self, rz)
  if rx == 0 then
    return
  end

  self.rotation = self.rotation + rz

  local trans = slick.newTransform(self.x, self.y, self.rotation)

  for _, level in ipairs(self.levels) do
    level.world:update(self, trans)
  end
end

local lg = love.graphics
colliderMulti.debugDraw = function(self)
  lg.push("all")
  lg.setColor(0,0,1,0.5)
  lg.translate(self.x, self.y)
  lg.rotate(self.rotation)
  for _, shape in ipairs(self.debugShapes) do
    if shape.shape == "rectangle" then
      lg.rectangle("fill", shape.x, shape.y, shape.width, shape.height)
    elseif shape.shape == "circle" then
      lg.circle("fill", shape.x, shape.y, shape.radius, shape.segments)
    end
  end
  lg.pop()
end

return colliderMulti