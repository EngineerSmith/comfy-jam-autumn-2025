local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

local logger = require("util.logger")

local character = { }
character.__index = character

character.create = function(x, y, speed, size)
  local self = setmetatable({
    x = x,
    y = y,
    previousX = x, previousY = y,
    speed = speed or 1,
    size = size or 1,
    levels = { },
  }, character)
  self.halfSize = self.size/2
  self.shape = slick.newRectangleShape(-self.halfSize, -self.halfSize, self.size, self.size,  slickHelper.types.CHARACTER)
  return self
end

character.addToLevel = function(self, level)
  if level:isInLevel(self) then
    logger.info("Character already added to this level")
    return
  end
  level:add(self, self.x, self.y, self.shape)
  self.levels[level] = true
end

character.removeFromLevel = function(self, level)
  if not level:isInLevel(self) then
    logger.info("Tried to remove character not added to level")
    return
  end
  level:remove(self)
  self.levels[level] = nil
end

character.move = function(self, dx, dy)
  local finalX, finalY = self.x + dx, self.y + dy
  
  local worldsMadeChange, MAX_ITERATIONS = false, 10
  for i = 1, MAX_ITERATIONS do
    worldsMadeChange = false

    local currentGoalX, currentGoalY = finalX, finalY
    for level in pairs(self.levels) do
      local actualX, actualY = level.world:move(self, currentGoalX, currentGoalY)
      if actualX ~= currentGoalX or actualY ~= currentGoalY then
        currentGoalX, currentGoalY = actualX, actualY
        worldsMadeChange = true
      end
    end
    finalX, finalY = currentGoalX, currentGoalY

    if not worldsMadeChange then
      break
    end

    if i == MAX_ITERATIONS then
      logger.warn("Character movement exceeded max iterations before convergence.")
    end
  end

  if finalX ~= self.x or finalY ~= self.y then
    self:teleport(finalX, finalY)
    return true
  end
  return false
end

character.teleport = function(self, x, y)
  for levels in pairs(self.levels) do
    level.world:update(self, x, y)
  end
  self.previousX, self.previousY = self.x, self.y
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