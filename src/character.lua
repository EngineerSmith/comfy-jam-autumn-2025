local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

local logger = require("util.logger")

local character = {
  _character = true,
}
character.__index = character

character.create = function(name, speed, size)
  local self = setmetatable({
    name  = name,
    speed = speed or 1,
    size  = size  or 1,
    x = 0, y = 0, z = 0,
    previousX = 0, previousY = 0,
    levels = { },
    levelCounter = 0,
  }, character)
  self.halfSize = self.size/2
  self.shape = slick.newCircleShape(0, 0, self.halfSize, 16, slickHelper.tags.CHARACTER)
  return self
end

character.addToLevel = function(self, level)
  if level:isInLevel(self) then
    logger.info("Character already added to this level '"..tostring(level.name).."'.")
    return
  end
  level:add(self, self.x, self.y, self.shape)
  self.levels[level] = true
  self.levelCounter = self.levelCounter + 1

  if self.levelCounter == 1 then
    self.z = level.zLevel
  end

  logger.info("Character added to "..tostring(level.name))
end

character.removeFromLevel = function(self, level)
  if not level:isInLevel(self) then
    logger.info("Tried to remove character not added to level '"..tostring(level.name).."'.")
    return
  end
  level:remove(self)
  self.levels[level] = nil
  self.levelCounter = self.levelCounter - 1

  if self.levelCounter == 1 then
    local activeLevel = next(self.levels)
    self.z = activeLevel.zLevel -- find only level, and set Z
  end

  logger.info("Character removed from "..tostring(level.name))
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
  for level in pairs(self.levels) do
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
    lg.setColor(1,1,1,1)
    if not self.z then print(self.levelCounter) end

    local levelName = "None"
    if self.levelCounter > 1 then
      levelName = "In Transition"
    elseif self.levelCounter == 1 then
      levelName = next(self.levels).name
    end

    lg.print(("%.1f:%1.f:%.1f %s"):format(self.x, self.y, self.z, levelName), 0, 20)
    lg.setColor(self.color)
    lg.rectangle("fill", -self.halfSize, -self.halfSize, self.size, self.size)
  end
  lg.pop()
end

return character