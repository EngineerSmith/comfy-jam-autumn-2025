local object = { }
object.__index = object

local flux = require("libs.flux")

local MAX_RADIUS = 1.7

object.new = function()
  local self = setmetatable({
    x = 0, y = 0, z = 0,
    flip = true,
    flipRZ = math.rad(-180),
    stateTextures = { },
    movedPreviousFrame = false,
    size = 0.5,
    idleTriggerTime = 3.0,
  }, object)

  self:setState("idle")
  return self
end

object.setState = function(self, state)
  -- if self.state == state and self.currentMesh then
  --   return
  -- end
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

local createPlaneForQuad = require("src.createPlaneForQuad")
object.setStateTexture = function(self, state, texture, frameCount, frameTime)
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