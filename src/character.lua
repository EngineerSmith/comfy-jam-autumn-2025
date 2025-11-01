local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

local logger = require("util.logger")
local colliderCircle = require("src.colliderCircle")

local character = {
  _character = true,
}
character.__index = character

character.create = function(name, speed, size, textureSizeMod)
  local self = setmetatable({
    name  = name,
    speed = speed or 1,
    size  = size  or 1,
    textureSizeMod = textureSizeMod,
    x = 0, y = 0, z = 0,
    previousX = 0, previousY = 0,
    rotation = 0,
    levels = { },
    levelCounter = 0,
    stateTextures = { },
    movedPreviousFrame = false,
  }, character)
  self.halfSize = self.size/2
  self.shape = slick.newCircleShape(0, 0, self.halfSize * textureSizeMod, 16, slickHelper.tags.CHARACTER)
  self:setState("idle")
  return self
end

character.setState = function(self, state)
  self.state = state
  
  local stateData = self.stateTextures[self.state]
  if stateData and stateData.frameCount > 0 then
    self.timer = 0
    self.currentFrame = 1
    self.currentMesh = stateData.meshes[self.currentFrame]
  end
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

local createPlaneForQuad = require("src.createPlaneForQuad")
character.setStateTexture = function(self, state, texture, frameCount, frameTime)
  local textureWidth, textureHeight = texture:getDimensions()

  local paddingNormWidth  = 1 / textureWidth
  local paddingNormHeight = 1 / textureHeight

  local widthNormQuad = 1 / frameCount

  local meshes = { }

  local vStart = paddingNormHeight
  local wNormQuad = widthNormQuad - ( 2 * paddingNormWidth)
  local hNormQuad = 1.0 - (2 * paddingNormHeight)
  for i = 1, frameCount do
    local uStart = (i - 1) * widthNormQuad + paddingNormWidth
    meshes[i] = createPlaneForQuad(uStart, vStart, wNormQuad, hNormQuad, texture, self.halfSize)
  end

  self.stateTextures[state] = {
    texture = texture,
    frameTime = frameTime,
    frameCount = frameCount,
    meshes = meshes,
  }

  if self.state == state then
    self:setState(self.state)
  end
end

character.move = function(self, dx, dy)
  self.rotation = math.atan2(dy, dx) - math.rad(90)

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
    self.movedPreviousFrame = true
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
  if self.movedPreviousFrame and self.state == "idle" then
    self:setState("walking")
  elseif not self.movedPreviousFrame and self.state == "walking" then
    self:setState("idle")
  end

  local stateData = self.stateTextures[self.state]

  if stateData and stateData.frameCount > 1 then
    self.timer = self.timer + dt
    while self.timer >= stateData.frameTime do
      self.timer = self.timer - stateData.frameTime
      self.currentFrame = self.currentFrame % stateData.frameCount + 1
      self.currentMesh = stateData.meshes[self.currentFrame]
    end
  end
end

local lg = love.graphics
character.debugDraw = function(self)
  lg.push("all")
  lg.translate(math.floor(self.x), math.floor(self.y))
  if self.color then
    lg.setColor(1,1,1,1)
    if not self.z then print(self.levelCounter) end

    lg.setColor(self.color)
    lg.circle("fill", 0, 0, self.halfSize * self.textureSizeMod, self.segments)
  end
  lg.pop()
end

character.draw = function(self)
  if not self.currentMesh then
    return
  end
  lg.push("all")
  lg.setColor(1,1,1,1)
  self.currentMesh:setTranslation(self.x, self.y, self.z)
  self.currentMesh:setRotation(0, 0, self.rotation)
  self.currentMesh:draw()
  lg.pop()
end

return character