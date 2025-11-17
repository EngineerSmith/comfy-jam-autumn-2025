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
local suit = require("libs.suit").new()
local enum = require("util.enum")
local ui = require("util.ui")
audioManager.setVolumeAll()

local settingsMenu = require("ui.menu.settings")
settingsMenu.set(suit)
suit.theme = require("ui.theme.menu")

local g3d = require("libs.g3d")

local dir = { .8, .8, .4 }
local mag = math.sqrt(dir[1]*dir[1]+dir[2]*dir[2]+dir[3]*dir[3])
dir[1], dir[2], dir[3] = dir[1] / mag, dir[2] / mag, dir[3] / mag
g3d.shader:send("lightDirection", dir)

local scriptingEngine = require("src.scripting")
local musicPlayer = require("src.musicPlayer")
local transition = require("src.transition")
local player = require("src.player")
local world = require("src.world")

local credits = [[
A Pot to Call Home: Cookie's Autumn Forage
Built By EngineerSmith (Code, Design, Art, and 2D animations)

---

3D Assets & Textures
EngineerSmith
Kenney
Nature Kit; Food Kit; Pirate Kit; Input Icons

---

Audio
Music (Title Screen/Overworld): Poltergasm
Music (Inside Nest): Kenney
Sound Effects (SFX): Licensed To EngineerSmith, Kenney (Various packs)

---

Tools & Libraries
Game Framework: LÖVE (love2d.org)

Key Libraries:
g3d: (Modified) 3D Graphics & Shaders
Slick: Physics Library
Lily: Concurrent Asset Loader

---

There's a total of 71 leaves you can collect!
Did you get them all?

Thanks for playing
]]

local scene = {
  minimap = {
    enabled = false, -- disable for release
    size = 512,
    scale = 5,
  },
  isCreditsPlaying = false,
  creditsScrollY = 0,
  creditsFade = 0,
  creditsLines = { },
  creditsScrollSpeed = 90,
  creditsLineSpacing = 1.25,
  creditsFadeDuration = 1.5,
}
scene.cutsceneCamera = g3d.camera.newCamera()
scene.cutsceneCamera.fov = math.rad(50)

if scene.minimap.enabled then
  scene.minimap.canvas = lg.newCanvas(scene.minimap.size, scene.minimap.size)
end

scene.preload = function()
  settingsMenu.preload()
end

scene.load = function()
  love.mouse.setRelativeMode(false)
  love.mouse.setVisible(true)
  settingsMenu.load()

  -- Load/keep loaded the main menu to return
  sceneManager.preload("scenes.mainmenu")

  player.initialisePlayerCamera()
  player.camera:setCurrent()

  world.load()

  musicPlayer.start()

  scriptingEngine.startScript("event.newgame")
end

scene.unload = function()
  settingsMenu.unload()
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

  -- scale UI
  suit.scale = scene.scale
  suit.theme.scale = scene.scale

  -- scale Text
  local font = ui.getFont(18, "fonts.regular.bold", scene.scale)
  lg.setFont(font)

  -- scale Cursor
  cursor.setScale(scene.scale)
  ----

  player.setAspectRatio(w / h)
  scene.cutsceneCamera.aspectRatio = w / h
  scene.cutsceneCamera:updateProjectionMatrix()
  require("src.world.nest").setAspectRatio(w / h)
end

scene.update = function(dt)
  musicPlayer.update()
  if not scene.showingSettings then
    world.update(dt, scene.scale)
    transition.update(dt)
  end

  if scene.isCreditsPlaying then
    local isMouseDown = input.baton:down("skip")
    scene.creditsScrollY = scene.creditsScrollY - scene.creditsScrollSpeed * dt * (isMouseDown and 4 or 1)
    local screenHeight = lg.getHeight()
    local lastLineY = scene.creditsScrollY + scene.creditsTotalHeight
    local y = screenHeight * 0.25
    if lastLineY < y then
      scene.isCreditsPlaying = false
      flux.to(scene, scene.creditsFadeDuration, { creditsFade = 0.0 })
        :ease("quadout")
        :oncomplete(function()
          if scene.creditsCallback then
            scene.creditsCallback()
            scene.creditsCallback = nil
          end
        end)
    end
  end

  if scene.showingSettings then
    settingsMenu.update(dt)
  end
end

scene.playCredits = function(callback)
  if scene.isCreditsPlaying then return end
  scene.isCreditsPlaying = true

  logger.info("Starting credits...")
  scene.creditsCallback = callback

  scene.creditsLines = { }
  scene.creditsTotalHeight = 0
  local currentFont = lg.getFont()
  local lineHeight = currentFont:getHeight() * scene.creditsLineSpacing
  local screenW = lg.getWidth()
  local screenH = lg.getHeight()
  local currentY = 0

  for line in string.gmatch(credits, "([^\n]*)") do
    local textWidth = currentFont:getWidth(line)
    local xPos = (screenW - textWidth) / 2
    table.insert(scene.creditsLines, {
      text = line,
      x = xPos,
      y = currentY
    })
    currentY = currentY + lineHeight
  end

  scene.creditsTotalHeight = currentY
  scene.creditsScrollY = screenH
  flux.to(scene, scene.creditsFadeDuration, { creditsFade = 1.0 }):ease("quadin")
end

scene.updateui = function()
  if scene.showingSettings then
    suit:enterFrame()
    if settingsMenu.updateui() then
      scene.showingSettings = false
    end
  end
end

scene.draw = function()
  love.graphics.clear(0.172, 0.273, 0.343) -- dark sky blue
  lg.push("all")
    world.draw(scene.scale)
  lg.pop()

  transition.draw()

  if scene.creditsFade > 0 then
    local screenW, screenH = lg.getDimensions()
    lg.setColor(0,0,0, scene.creditsFade * .8)
    lg.rectangle("fill", 0, 0, screenW, screenH)
    lg.push("all")
    lg.translate(0, scene.creditsScrollY)
    lg.setColor(1, 1, 1, scene.creditsFade)

    for _, lineInfo in ipairs(scene.creditsLines) do
      lg.print(lineInfo.text, lineInfo.x, lineInfo.y)
    end
    lg.pop()
  end

  if scene.minimap.enabled and world.stage == "world" then
    lg.push("all")
      lg.origin()
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

  if scene.showingSettings then
    lg.push("all")
    lg.setColor(0,0,0,0.7)
    lg.rectangle("fill", 0,0, lg.getDimensions())
    lg.pop()
    suit:draw(1)
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

scene.mousemoved = function(...)
  world.mousemoved(scene.scale, ...)
end

return scene