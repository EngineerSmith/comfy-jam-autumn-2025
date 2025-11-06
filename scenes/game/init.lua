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

local CUBE = g3d.newModel("scenes/game/cube.obj", nil, nil, { 5, 0, 0 })
cam:lookAt(0,1e-5,25,0,0,0)

local musicPlayer = require("src.musicPlayer")
local player = require("src.player")
local world = require("src.world")

local scene = {
  minimap = {
    enabled = true,
    size = 256,
    scale = 3,
  }
}

if scene.minimap.enabled then
  scene.minimap.canvas = lg.newCanvas(scene.minimap.size, scene.minimap.size)
end

scene.load = function(roomInfo)
  love.mouse.setRelativeMode(false)
  love.mouse.setVisible(true)

  -- Load/keep loaded the main menu to return
  sceneManager.preload("scenes.mainmenu")
  world.load()

  musicPlayer.start()
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
  musicPlayer.update()
  world.update(dt)

  -- local t = love.timer.getTime()
end

scene.draw = function()
  love.graphics.clear()
  -- love.graphics.clear(33/255, 117/255, 7/255)
  lg.push("all")
    -- CUBE:draw()
    world.draw()
  lg.pop()

  if scene.minimap.enabled then
    lg.push("all")
      lg.setCanvas(scene.minimap.canvas)
      lg.clear(.1,.1,.1, 1)
      local playerX, playerY, playerZ = player.getPosition()
      local halfMap = scene.minimap.size / 2
      lg.translate(halfMap, halfMap)
      lg.scale(scene.minimap.scale, -scene.minimap.scale)
      lg.translate(-playerX, -playerY)
      world.debugDraw()
    lg.pop()
    lg.push("all")
      local screenX = lg.getWidth() - scene.minimap.size - 20
      local screenY = 20
      lg.translate(screenX, screenY)
      lg.setColor(1,1,1,1)
      lg.draw(scene.minimap.canvas)
      lg.setLineWidth(2)
      lg.rectangle("line", 0, 0, scene.minimap.size, scene.minimap.size)

      local char = player.character
      local levelName = "None"
      if char then
        if char.levelCounter > 1 then
          levelName = "In Transition"
        elseif char.levelCounter == 1 then
          levelName = next(char.levels).name
        end
      end

      lg.print(("%.1f:%.1f:%.1f\n%s"):format(playerX, playerY, playerZ, levelName), 0, scene.minimap.size + 20)
    lg.pop()
  end
end

scene.keypressed = function(_, key)
  if key == "c" and love.keyboard.isScancodeDown("lctrl", "rctrl") then
    local playerX, playerY, playerZ = player.getPosition()
    local str = ("x = %g, y = %g"):format(playerX, playerY)
    love.system.setClipboardText(str)
  end
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