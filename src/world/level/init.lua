local level = { }
level.__index = level

local slick = require("libs.slick")

local logger = require("util.logger")

local BOUNDARY_MARGIN = 10

level.new = function(name, width, height, positionOffsetX, positionOffsetY)
  width = width or 100
  height = height or width
  positionOffsetX = positionOffsetX or 0
  positionOffsetY = positionOffsetY or 0
  local halfWidth, halfHeight = width / 2, height / 2

  return setmetatable({
    name = name,
    offsetX = positionOffsetX,
    offsetY = positionOffsetY,
    boundRadius = math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight) + BOUNDARY_MARGIN,
    world = slick.newWorld(width, height, {
        quadTreeX = -halfWidth + positionOffsetX,
        quadTreeY = -halfHeight + positionOffsetY,
      }),
    characters = { },
  }, level)
end

level.isInLevel = function(self, item)
  return self.world:has(item)
end

level.add = function(self, item, ...)
  if level:isInLevel(item) then
    return nil
  end
  if type(item) == "table" and item._character == true then
    table.insert(self.characters, item)
  end
  return self.world:add(item, ...)
end

level.remove = function(self, item, ...)
  if not level:isInLevel(item) then
    return nil
  end
  if type(item) == "table" and item._character == true then
    for i, c in ipairs(self.characters) do
      if c == item then
        table.remove(self.characters, i)
      end
    end
  end
  return self.world:remove(item, ...)
end

level.update = function(self, dt)
  for _, character in ipairs(self.characters) do
    local dx, dy = character.x - self.offsetX, character.y - self.offsetY
    local mag = math.sqrt(dx * dx + dy * dy)
    if mag >= self.boundRadius then
      character:teleport(-self.offsetX, self.offsetY) -- for now, teleport to centre
      logger.warn("Character was found outside of level bounds, teleported to centre.")
    end
  end
end

return level