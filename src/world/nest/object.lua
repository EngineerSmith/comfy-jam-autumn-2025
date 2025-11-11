local object = { }
object.__index = object

local flux = require("libs.flux")

local MAX_RADIUS = 1.7

object.new = function(size)
  local self = setmetatable({
    x = 0, y = 0, z = 0,
    flip = true,
    flipRZ = math.rad(-180),
    stateTextures = { },
    movedPreviousFrame = false,
    size = size or 0.5,
    idleTriggerTime = 3.0,
    currentFrame = 1,
    timer = 0,
    idleTimer = 0,
  }, object)

  self:setState("idle")
  return self
end

object.playCurrentSubState = function(self)
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

object.setState = function(self, state, force)
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
    else
      self.subState = nil
      self.stateData = nil
    end
  end
end

local createPlaneForQuad = require("src.createPlaneForQuad")
object.setStateTexture = function(self, state, subState, texture, frameCount, frameTime)
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
    local uStart = paddingNormWidth + ((i - 1) * widthNormQuad)
    table.insert(meshes, createPlaneForQuad(uStart, vStart, wNormQuad, hNormQuad, texture, self.size, "XZ"))
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

  -- if self.state == state and self.subState == subState then
  --   self:playCurrentSubState()
  -- end
  if self.state == state then
    self:setState(self.state, true)
  end
end

object.move = function(self, deltaX, deltaY, ignoreBounds)
  self.x = self.x + deltaX
  self.y = self.y + deltaY

  -- if not ignoreBounds then
  --   local mag = math.sqrt(self.x * self.x + self.y * self.y)
  --   if mag > MAX_RADIUS - self.size / 1.95 then
  --     local scale = (MAX_RADIUS - self.size / 1.95) / mag
  --     self.x = self.x * scale
  --     self.y = self.y * scale
  --   end
  -- end

  local state = math.abs(deltaX) > 0 and "walking" or "idle"
  if state == "walking" then
    local currentFlip = self.flip
    self.flip = deltaX > 0
    if currentFlip ~= self.flip then
      if self.flipTween then
        self.flipTween:stop()
      end
      if not self.flip then
        self.flipRZ = math.rad(0)
        self.flipTween = flux.to(self, 0.15, { flipRZ = math.rad(-180) })
      else
        self.flipRZ = math.rad(-180)
        self.flipTween = flux.to(self, 0.15, { flipRZ = math.rad(0) })
      end
    end
  end
  self.movedPreviousFrame = true
end

object.setFlip = function(self, flipped)
  if flipped == nil then
    self.flip = self.flip
  else
    self.flip = flipped
  end

  if self.flip then
    self.flipRZ = math.rad(-180)
  else
    self.flipRZ = math.rad(0)
  end
  return self
end

object.update = function(self, dt)
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
object.draw = function(self)
  if not self.currentMesh then
    return
  end
  lg.push("all")
    lg.setColor(1,1,1,1)
    self.currentMesh:setTranslation(self.x, self.y, self.z + 3e-3) -- add jiggle to avoid it's own shadow
    self.currentMesh:setRotation(0, 0, self.flipRZ)
    self.currentMesh:draw()
  lg.pop()
end

return object