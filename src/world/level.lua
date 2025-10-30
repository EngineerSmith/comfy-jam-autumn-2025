local level = { }
level.__index = level

local slick = require("libs.slick")

local logger = require("util.logger")

local BOUNDARY_MARGIN = 100

level.new = function(name, x, y, width, height, zLevel)
  x      = x or 0
  y      = y or 0
  width  = width or 100
  height = height or width
  zLevel = zLevel or 0

  local halfWidth, halfHeight = width / 2, height / 2

  return setmetatable({
    name = name,
    centreX = x + halfWidth,
    centreY = y + halfHeight,
    zLevel  = zLevel,
    boundRadius = math.sqrt(halfWidth * halfWidth + halfHeight * halfHeight) + BOUNDARY_MARGIN,
    world = slick.newWorld(width, height, {
      quadTreeX = x,
      quadTreeY = y,
    }),
    rect = { x, y, width, height },
    characters = { },
  }, level)
end

level.isInLevel = function(self, item)
  return self.world:has(item)
end

level.add = function(self, item, ...)
  if self:isInLevel(item) then
    return nil
  end
  if type(item) == "table" and item._character == true then
    table.insert(self.characters, item)
  end
  return self.world:add(item, ...)
end

level.remove = function(self, item, ...)
  if not self:isInLevel(item) then
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
    local dx, dy = character.x - self.centreX, character.y - self.centreY
    local mag = math.sqrt(dx * dx + dy * dy)
    if mag >= self.boundRadius then
      character:teleport(self.centreX, self.centreY) -- for now, teleport to centre
      logger.warn("Character was found outside of level bounds, teleported to centre.")
    end
  end
end

return level