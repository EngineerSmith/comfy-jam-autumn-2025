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

local scene = { }

local world = require("src.world")

scene.load = function(roomInfo)
  -- Load/keep loaded the main menu to return
  sceneManager.preload("scenes.mainmenu")
  world.load()
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
end

scene.update = function(dt)
  world.update(dt)
end

scene.draw = function()
  love.graphics.clear()
  world.draw()
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