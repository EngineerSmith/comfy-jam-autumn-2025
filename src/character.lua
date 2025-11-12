local slick = require("libs.slick")

local logger = require("util.logger")
local slickHelper = require("util.slickHelper")
local audioManager = require("util.audioManager")

local colliderCircle = require("src.colliderCircle")

local character = {
  _character = true,
}
character.__index = character

character.create = function(name, speed, size, zOffset, textureSizeMod)
  local self = setmetatable({
    name  = name,
    speed = speed or 1,
    size  = size  or 1,
    zOffset = zOffset or 0.2,
    textureSizeMod = textureSizeMod,
    x = 0, y = 0, z = 0,
    previousX = 0, previousY = 0,
    rotation = 0,
    levels = { },
    levelCounter = 0,
    stateTextures = { },
    stateData = nil,
    movedPreviousFrame = false,
    idleTimer = 0,
    idleTriggerTime = 3,
  }, character)
  self.halfSize = self.size/2
  self.shape = slick.newCircleShape(0, 0, self.halfSize * textureSizeMod, 16, slickHelper.tags.CHARACTER)
  self:setState("idle")
  return self
end

character.setState = function(self, state)
  self.state = state

  local stateData = self.stateTextures[self.state]
  if stateData then
    self.stateData = stateData[love.math.random(#stateData)]
    self.timer = 0
    self.currentFrame = 1
    self.currentMesh = self.stateData.meshes[self.currentFrame]
  end

  if state == "idle" then
    self.idleTimer = 0
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

character.isInLevel = function(self, level)
  return self.levels[level] ~= nil
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

  local totalPaddingStrips = frameCount + 1
  local totalPaddingPixels = totalPaddingStrips

  local visibleFrameWidthPixels  = (textureWidth - totalPaddingPixels) / frameCount
  local visibleFrameHeightPixels = textureHeight - 2

  local wNormQuad = visibleFrameWidthPixels / textureWidth
  local widthNormQuad = (visibleFrameWidthPixels + 1) / textureWidth

  local vStart = paddingNormHeight
  local hNormQuad = visibleFrameHeightPixels / textureHeight

  local meshes = { }
  for i = 1, frameCount do
    -- local uStart = (i - 1) * widthNormQuad + paddingNormWidth
    local uStart = paddingNormWidth + ((i - 1) * widthNormQuad)
    table.insert(meshes, createPlaneForQuad(uStart, vStart, wNormQuad, hNormQuad, texture, self.halfSize))
  end

  if not self.stateTextures[state] then
    self.stateTextures[state] = { }
  end

  table.insert(self.stateTextures[state],  {
    texture = texture,
    frameTime = frameTime,
    frameCount = frameCount,
    meshes = meshes,
  })

  if self.state == state then
    self:setState(self.state)
  end
end

local SNAP_STEP = 360 / 16
local snapAngleTo16Directions = function(nx, ny)
  if math.abs(nx) < 1e-3 and math.abs(ny) < 1e-3 then
    return nil -- No significant movement
  end

  local rawAngleDeg = math.deg(math.atan2(ny, nx))

  return math.floor((rawAngleDeg / SNAP_STEP) + 0.5) * SNAP_STEP
end

local getSnappedVector = function(x, y, snappedDeg)
  local mag = math.sqrt(x * x + y * y)
  local snappedRad = math.rad(snappedDeg)
  local snappedX = math.cos(snappedRad) * mag
  local snappedY = math.sin(snappedRad) * mag
  return snappedX, snappedY
end

character.faceDirection = function(self, nx, ny)
  local snappedDeg = snapAngleTo16Directions(nx, ny)
  if snappedDeg then
    self.rotation = math.rad(snappedDeg - 90) -- graphic faces up, account for this
  end
end

local noCollisions = function() return false end

character.move = function(self, dx, dy, inPhase)
  local snappedDeg = snapAngleTo16Directions(dx, dy)
  if not snappedDeg then
    return
  end

  local snappedDx, snappedDy = getSnappedVector(dx, dy, snappedDeg)

  local finalX, finalY = self.x + snappedDx, self.y + snappedDy

  local worldsMadeChange, MAX_ITERATIONS = false, 10
  for i = 1, MAX_ITERATIONS do
    worldsMadeChange = false

    local currentGoalX, currentGoalY = finalX, finalY
    for level in pairs(self.levels) do
      local actualX, actualY = level.world:move(self, currentGoalX, currentGoalY, inPhase and noCollisions or nil)
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
    self:faceDirection(snappedDx, snappedDy)
    return true
  end
  return false
end

local movementTolerance = 1e-3
character.canMoveTo = function(self, goalX, goalY)
  local canMove = true
  for level in pairs(self.levels) do
    local actualX, actualY = level.world:check(self, goalX, goalY)
    if math.abs(actualX - goalX) > movementTolerance or
       math.abs(actualY - goalY) > movementTolerance
      then
      canMove = false
      break
    end
  end
  return canMove
end

character.teleport = function(self, x, y)
  for level in pairs(self.levels) do
    level.world:update(self, x, y)
  end
  self.previousX, self.previousY = self.x, self.y
  self.x, self.y = x, y
end

character.teleportBy = function(self, dx, dy)
  local x, y = dx + self.x, dy + self.y
  self:teleport(x, y)
end

character.update = function(self, dt)
  if self.movedPreviousFrame and self.state == "idle" then
    self:setState("walking")
  elseif not self.movedPreviousFrame and self.state == "walking" then
    self:setState("idle")
  end
  self.movedPreviousFrame = false

  if self.state == "idle" then
    self.idleTimer = self.idleTimer + dt
    if self.idleTimer >= self.idleTriggerTime then
      local fidgetData = self.stateTextures["idle_fidget"]
      if fidgetData then
        self:setState("idle_fidget")
      else
        self.idleTimer = 0
      end
    end
  end

  if self.stateData and self.stateData.frameCount > 1 then
    self.timer = self.timer + dt
    while self.timer >= self.stateData.frameTime do
      self.timer = self.timer - self.stateData.frameTime
      self.currentFrame = self.currentFrame + 1
      if self.state == "walking" then
        audioManager.play("audio.fx.footstep.grass")
      end
      if self.state == "idle_fidget" and self.currentFrame == self.stateData.frameCount then
        self:setState("idle")
        break
      elseif self.currentFrame > self.stateData.frameCount then
        self:setState(self.state)
        break
      else
        self.currentMesh = self.stateData.meshes[self.currentFrame]
      end
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
  self.currentMesh:setTranslation(self.x, self.y, self.z + self.zOffset)
  self.currentMesh:setRotation(0, 0, self.rotation)
  self.currentMesh:draw()
  lg.pop()
end

return character