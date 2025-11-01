local lg = love.graphics

local sceneManager = require("util.sceneManager")
local audioManager = require("util.audioManager")
local assetManager = require("util.assetManager")
local settings = require("util.settings")
local options = require("util.option")
local logger = require("util.logger")
local cursor = require("util.cursor")
local input = require("util.input")
local lang = require("util.lang")
local flux = require("libs.flux")
local enum = require("util.enum")
local ui = require("util.ui")
audioManager.setVolumeAll()

local g3d = require("libs.g3d")

local dir = { .8, .8, .4 }
local mag = math.sqrt(dir[1]*dir[1]+dir[2]*dir[2]+dir[3]*dir[3])
dir[1], dir[2], dir[3] = dir[1] / mag, dir[2] / mag, dir[3] / mag
g3d.shader:send("lightDirection", dir)

local cam = g3d.camera:current()
cam.fov = math.rad(50)
cam:updateProjectionMatrix()
cam.speed = 20

local CUBE = g3d.newModel("scenes/game/cube.obj", nil, nil, { 0, 0, 0 })

local player = require("src.player")
local world = require("src.world")

local scene = {
  lookAt = { 0, -4.3, 25 },
}

local updateCamera = function()
  local x, y, z = player.getPosition()
  local atX, atY, atZ = scene.lookAt[1], scene.lookAt[2], scene.lookAt[3]
  g3d.camera.current():lookAt(x, y, z, x + atX, y + atY, z + atZ)
end

scene.load = function(roomInfo)
  -- Load/keep loaded the main menu to return
  sceneManager.preload("scenes.mainmenu")
  world.load()
  -- updateCamera()
end

scene.unload = function()
  world.unload()
end

scene.resize = function(w, h)
  -- Update settings
  settings.client.resize(w, h)

  -- Scale scene
  local wsize = settings._default.client.windowSize
  local tw, th = wsize.width, wsize.height
  local sw, sh = w / tw, h / th
  scene.scale = sw < sh and sw or sh

  -- scale Text
  local font = ui.getFont(18, "fonts.regular.bold", scene.scale)
  lg.setFont(font)

  -- scale Cursor
  cursor.setScale(scene.scale)
  ----

  local cam = g3d.camera:current()
  cam.aspectRatio = w/h
  cam:updateProjectionMatrix()
end

scene.update = function(dt)
  world.update(dt)
  -- updateCamera()
  local cam = g3d.camera:current()
  cam:firstPersonMovement(dt)
  -- print(">", unpack(cam.position))

  local t = love.timer.getTime()
  CUBE:setTranslation(math.cos(t)*5, math.sin(t)*5 + 4, 0)
  CUBE:setRotation(0, 0, math.pi - t)
end

scene.draw = function()
  love.graphics.clear()
  lg.push("all")
    lg.translate(math.floor(lg.getWidth()/2), math.floor(lg.getHeight()/2))
    world.debugDraw()
  lg.pop()
  lg.push("all")
    CUBE:draw()
    world.draw()
  lg.pop()
end

scene.joystickadded = function(...)
  input.joystickadded(...)
end

scene.joystickremoved = function(...)
  input.joystickremoved(...)
end

scene.gamepadpressed = function(...)
  input.gamepadpressed(...)
end

return scene