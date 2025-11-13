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
    ---
    stateTextures = { },
    stateData = nil,
    subState = nil,
    nextState = nil,
    currentFrame = 1,
    timer = 0,
    movedPreviousFrame = false,
    idleTimer = 0,
    idleTriggerTime = 3,
  }, character)
  self.halfSize = self.size/2
  self.shape = slick.newCircleShape(0, 0, self.halfSize * textureSizeMod, 16, slickHelper.tags.CHARACTER)
  self:setState("idle")
  return self
end

character.playCurrentSubState = function(self)
  local stateDataGroup = self.stateTextures[self.state]
  if not stateDataGroup then
    self.stateData = nil
    return
  end

  local subStateDataArray = stateDataGroup[self.subState]
  if subStateDataArray and #subStateDataArray > 0 then
    self.stateData = subStateDataArray[love.math.random(#subStateDataArray)]
    self.timer = 0
    self.currentFrame = 1
    self.currentMesh = self.stateData.meshes[self.currentFrame]
  else
    self.stateData = nil
  end
end

character.setState = function(self, state, force)
  if state == nil then
    return
  end

  if self.state == state and self.subState ~= "exit" and not force then
    return
  end

  local oldStateData = self.stateTextures[self.state]
  if oldStateData and oldStateData.exit and self.subState ~= "exit" then
    self.nextState = state
    self.subState = "exit"
    self:playCurrentSubState()
  else
    self.state = state
    self.nextState = nil
    self.idleTimer = 0
    
    local newStateData = self.stateTextures[self.state]
    if newStateData and newStateData.start then
      self.subState = "start"
      self:playCurrentSubState()
    elseif newStateData and newStateData.loop then
      self.subState = "loop"
      self:playCurrentSubState()
    elseif newStateData and newStateData.finish then
      self.subState = "finish"
      self:playCurrentSubState()
    else
      self.subState = nil
      self.stateData = nil
    end
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
character.setStateTexture = function(self, state, subState, texture, frameCount, frameTime)
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
  if not self.stateTextures[state][subState] then
    self.stateTextures[state][subState] = { }
  end

  table.insert(self.stateTextures[state][subState],  {
    texture = texture,
    frameTime = frameTime,
    frameCount = frameCount,
    meshes = meshes,
  })

  if self.state == state then
    self:setState(self.state, true)
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

character.getFacingDirection = function(self)
  return self.rotation + math.rad(90)
end

local noCollisions = function() return false end

local noCharacterCollisions = function(_, _, shape, otherShape)
  return not (shape.tag.value.type == otherShape.tag.value.type)
end

local noCharacterCollisionsTOUCH = function(...)
  local bool = noCharacterCollisions(...)
  if bool == false then
    return "touch"
  end
  return bool
end

character.move = function(self, dx, dy, inPhase)
  local snappedDeg = snapAngleTo16Directions(dx, dy)
  if not snappedDeg then
    return
  end

  local snappedDx, snappedDy = getSnappedVector(dx, dy, snappedDeg)

  local finalX, finalY = self.x + snappedDx, self.y + snappedDy

  local worldQuery = inPhase == true and noCollisions
  if type(inPhase) == "string" then
    if inPhase == "touch" then
      worldQuery = noCharacterCollisionsTOUCH
    end
  elseif not worldQuery then
    worldQuery = noCharacterCollisions
  end

  local worldsMadeChange, MAX_ITERATIONS = false, 10
  for i = 1, MAX_ITERATIONS do
    worldsMadeChange = false

    local currentGoalX, currentGoalY = finalX, finalY
    for level in pairs(self.levels) do
      local actualX, actualY, collisions = level.world:move(self, currentGoalX, currentGoalY, worldQuery)
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
    self:faceDirection(snappedDx, snappedDy)
    return true
  end
  return false
end

local movementTolerance = 1e-3
character.canMoveTo = function(self, goalX, goalY, inPhase)
  local worldQuery = inPhase == true and noCollisions
  if type(inPhase) == "string" then
    if inPhase == "touch" then
      worldQuery = noCharacterCollisionsTOUCH
    end
  elseif not worldQuery then
    worldQuery = noCharacterCollisions
  end

  local canMove = true
  for level in pairs(self.levels) do
    local actualX, actualY = level.world:check(self, goalX, goalY, worldQuery)
    if math.abs(actualX - goalX) > movementTolerance or
       math.abs(actualY - goalY) > movementTolerance
      then
      canMove = false
      break
    end
  end
  return canMove
end

character.canMoveBy = function(self, deltaX, deltaY, inPhase)
  local goalX = self.x + deltaX
  local goalY = self.y + deltaY
  return self:canMoveTo(goalX, goalY, inPhase)
end

character.getTagsBetween = function(self, startX, startY, deltaX, deltaY, inPhase)
  local worldQuery = inPhase == true and noCollisions
  if type(inPhase) == "string" then
    if inPhase == "touch" then
      worldQuery = noCharacterCollisionsTOUCH
    end
  elseif not worldQuery then
    worldQuery = noCharacterCollisions
  end

  local goalX, goalY = startX + deltaX, startY + deltaY
  local tags, lookup = { }, { }
  for level in pairs(self.levels) do
    local collisions = level.world:project(self, startX, startY, goalX, goalY)
    for _, result in ipairs(collisions) do
      if result.item ~= self and result.shape and result.shape.tag then
        local tagType = result.shape.tag.value.type
        if tagType and not lookup[tagType] then
          lookup[tagType] = true
          table.insert(tags, tagType)
        end
      end
      if result.other ~= self and result.otherShape and result.otherShape.tag then
        local tagType = result.otherShape.tag.value.type
        if tagType and not lookup[tagType] then
          lookup[tagType] = true
          table.insert(tags, tagType)
        end
      end
    end
  end
  if #tags == 0 then
    return nil
  end
  return slickHelper.typeArrayToTags(tags)
end

character.teleport = function(self, x, y)
  for level in pairs(self.levels) do
    level.world:update(self, x, y)
  end
  self.previousX, self.previousY = self.x, self.y
  self.x, self.y = x, y
  self.movedPreviousFrame = true
end

character.teleportBy = function(self, dx, dy)
  local x, y = dx + self.x, dy + self.y
  self:teleport(x, y)
end

character.update = function(self, dt)
  self.frameChanged = false

  if self.stateTextures["walking"] then
    if self.movedPreviousFrame and self.state == "idle" then
      self:setState("walking")
    elseif not self.movedPreviousFrame and self.state == "walking" then
      self:setState("idle")
    end
  end
  self.movedPreviousFrame = false

  if self.state == "idle" and self.subState == "loop" then
    self.idleTimer = self.idleTimer + dt
    if self.idleTimer >= self.idleTriggerTime then
      if self.stateTextures["idle_fidget"] then
        self:setState("idle_fidget")
      else
        self.idleTimer = 0
      end
    end
  end

  if not self.stateData or self.stateData.frameCount <= 1 then
    return
  end

  self.timer = self.timer + dt
  while self.timer >= self.stateData.frameTime do
    self.timer = self.timer - self.stateData.frameTime
    self.currentFrame = self.currentFrame + 1
    self.frameChanged = true

    if self.state == "walking" and self.currentFrame % 2 == 0 then
      audioManager.play("audio.fx.footstep.grass")
    end

    if self.currentFrame > self.stateData.frameCount then
      local currentSubState = self.subState
      if currentSubState == "start" then
        local stateDataGroup = self.stateTextures[self.state]
        if stateDataGroup and stateDataGroup.loop then
          self.subState = "loop"
          self:playCurrentSubState()
        else
          -- Check if we should fall back to default state
          if self.state ~= "idle" and self.stateTextures["idle"] then
            self:setState("idle")
            break
          else
            if self.state == "idle_fidget" then
              self:setState("idle")
              break
            else
              self.currentFrame = self.stateData.frameCount
              self.stateData = nil
              break
            end
          end
        end
      elseif currentSubState == "loop" then
        self:playCurrentSubState()
      elseif currentSubState == "exit" then
        local nextState = self.nextState
        self.state = nextState
        self.nextState = nil
        self.subState = nil
        self:setState(nextState)
        break
      elseif currentSubState == "finish" then
        if self.stateTextures["idle"] then
          self:setState("idle")
          break
        else
          self.currentFrame = self.stateData.frameCount
          self.stateData = nil
          break
        end
      else
        -- No sub-state defined, default to looping - this is a fallback, shouldn't happen if I didn't miss anything
        self.currentFrame = 1
        self.currentMesh = self.stateData.meshes[self.currentFrame]
      end
    end

    -- If we're still in a valid frame, update mesh
    if self.stateData and self.currentFrame <= self.stateData.frameCount then
      self.currentMesh = self.stateData.meshes[self.currentFrame]
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