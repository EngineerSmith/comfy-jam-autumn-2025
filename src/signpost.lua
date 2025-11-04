local lg = love.graphics

local signpost = { }
signpost.__index = signpost

local g3d = require("libs.g3d")

local ui = require("util.ui")
local player = require("src.player")

local CANVAS_WIDTH, CANVAS_HEIGHT = 1024, 256
local ratio = 150 -- pixels : 1 unit
local signpostCanvas = lg.newCanvas(CANVAS_WIDTH, CANVAS_HEIGHT)

local unitWidth = CANVAS_WIDTH / ratio
local unitHeight = CANVAS_HEIGHT / ratio

-- Vertex Format: x, y, z, u, v, r, g, b, a, nx, ny, nz
-- Color is white (uses texture), normal means face points along positive X axis
local color_normal = { 1, 1, 1, 1, 0, 1, 0 }
local signpostModel = g3d.newModel({
  { -unitWidth / 2, 0, unitHeight, 0, 0, unpack(color_normal) },
  { -unitWidth / 2, 0,          0, 0, 1, unpack(color_normal) },
  {  unitWidth / 2, 0, unitHeight, 1, 0, unpack(color_normal) },

  {  unitWidth / 2, 0, unitHeight, 1, 0, unpack(color_normal) },
  { -unitWidth / 2, 0,          0, 0, 1, unpack(color_normal) },
  {  unitWidth / 2, 0,          0, 1, 1, unpack(color_normal) },
}, nil, signpostCanvas)

local FADE_IN_TIME  = 0.5 -- seconds
local FADE_OUT_TIME = 1.0 -- seconds

-- How should sign posts be defined in mapData.lua; just x, y, z isn't enough
--    how do we define what needs to be drawn? To think about
signpost.new = function(x, y, z, radius, rotation, content, level)
  local self = setmetatable({
    x = x, y = y, z = z or 0,
    radius = radius or 5,
    rotation = rotation or 0,
    content = content,
    level = level,
    fade = 0.0,
  }, signpost)
  self:setState("hide")
  return self
end

local lerp = function(a, b, t)
  return a + (b - a) * t
end

signpost.setState = function(self, state)
  local previousState = self.state

  if self.state ~= state then
    self.state = state
    if previousState == "fadeIn" and state == "fadeOut" then
      self.timer = FADE_OUT_TIME * (1.0 - self.fade)
    elseif previousState == "fadeOut" and state == "fadeIn" then
      self.timer = FADE_IN_TIME * self.fade
    else
      self.timer = 0.0
    end
  end
end

signpost.update = function(self, dt)
  local px, py = player:getPosition()
  local dx, dy = self.x - px, self.y - py
  local mag = math.sqrt(dx * dx + dy * dy)
  local isClose = mag <= self.radius
  if isClose and (self.state == "hide" or self.state == "fadeOut") then
    self:setState("fadeIn")
  elseif not isClose and (self.state == "show" or self.state == "fadeIn") then
    self:setState("fadeOut")
  end

  -- BUG: What if we switch from fadeIn to fadeOut before it completes self.fade = 1;
  -- then the lerp will be jump to 1 and fade out. Causing an odd graphic appearance
  if self.state == "fadeIn" then
    self.timer = self.timer + dt
    local t = math.min(self.timer / FADE_IN_TIME, 1.0)
    self.fade = lerp(0.0, 1.0, t)
    if t >= 1.0 then
      self:setState("show")
    end
  elseif self.state == "fadeOut" then
    self.timer = self.timer + dt
    local t = math.min(self.timer / FADE_OUT_TIME, 1.0)
    self.fade = lerp(1.0, 0.0, t)
    if t >= 1.0 then
      self:setState("hide")
    end
  end

  if self.state == "show" then self.fade = 1.0 end
  if self.state == "hide" then self.fade = 0.0 end
end

signpost.debugDraw = function(self)
  lg.push("all")
  lg.translate(self.x, self.y)
  if self.state == "show" or self.state == "fadeIn" then
    lg.setColor(1, .5, 0, 1)
    lg.circle("fill", 0, 0, 1.0 + self.fade / 2)
  elseif self.state == "hide" or self.state == "fadeOut" then
    lg.setColor(.5, .25, 0, 1)
    lg.circle("fill", 0, 0, 0.5 + self.fade / 2)
  end
  lg.pop()
end

-- Ensure signpost is drawn last with transparent textures
signpost.draw = function(self)
  if self.state == "hide" then
    return
  end

  lg.push("all")
  lg.setCanvas(signpostCanvas)
  lg.clear(0,0,0,0)
  lg.setColor(.1,.1,.1, .8)
  lg.rectangle("fill", 0,0, CANVAS_WIDTH, CANVAS_HEIGHT, 16)
  lg.setColor(1,1,1,1)
  local font = ui.getFont(72, "fonts.regular.bold")
  local contentWidth = font:getWidth(self.content)
  local contentHeight = font:getHeight()
  lg.print(self.content, font, math.floor(CANVAS_WIDTH / 2 - contentWidth / 2), math.floor(CANVAS_HEIGHT / 2 - contentHeight / 2))
  lg.pop()

  lg.push("all")
  lg.setColor(1,1,1, self.fade)
  signpostModel:setTranslation(self.x, self.y, self.z + self.level.zLevel)
  signpostModel:setRotation(-math.rad(20), 0, self.rotation)
  signpostModel:draw()
  lg.pop()
end

return signpost