local slick = require("libs.slick")
local slickInfo = require("src.slick")

local logger = require("util.logger")

local character = { }
character.__index = character

character.create = function(x, y, speed, size)
  local self = setmetatable({
    x = x,
    y = y,
    speed = speed or 1,
    size = size or 1,
  }, character)
  self.halfSize = self.size/2
  return self
end

character.addToWorld = function(self, world)
  world:add(self, self.x, self.y, slick.newRectangleShape(-self.halfSize, -self.halfSize, self.size, self.size, slickInfo.types.CHARACTER))
  self._world = world
end

character.removeFromWorld = function(self)
    if not self._world then
    logger.info("Tried to remove character not added to world")
    return
  end
  self._world:remove(self)
  self._world = nil
end

character.move = function(self, dx, dy)
  if not self._world then
    logger.info("Tried to move character not added to world")
    return
  end
  self.x, self.y = self._world:move(self, self.x + dx, self.y + dy)
end

character.teleport = function(self, x, y)
  if not self._world then
    logger.info("Tried to teleport character not added to world")
    return
  end
  self._world:update(self, x, y)
  self.x, self.y = x, y
end

character.update = function(self, dt)

end

local lg = love.graphics
character.draw = function(self)
  lg.push("all")
  lg.translate(math.floor(self.x), math.floor(self.y))
  if self.color then
    lg.setColor(self.color)
    lg.rectangle("fill", self.x-self.halfSize, self.y-self.halfSize, self.size, self.size)
  end
  lg.pop()
end

return character