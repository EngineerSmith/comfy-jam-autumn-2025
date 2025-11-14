local baton = require("libs.baton")

local logger = require("util.logger")
local settings = require("util.settings")

local input = {
  baton = baton.new({
    controls = settings.client.input,
    pairs = {
      move = { "moveRight", "moveLeft", "moveUp", "moveDown" },
      -- face = { "targetRight", "targetLeft", "moveUp", "moveDown" },
      target = { "targetRight", "targetLeft", "targetUp", "targetDown" },
    },
    joystick = joystick,
    deadzone = settings.client.deadzone,
  }),
}

local setBatonJoystick = function(joystick)
  input.baton.config.joystick = joystick
end

input.update = function()
  input.baton:update()
end

local keyboardAssetMap = { -- todo split into two lookup tables
  -- keyboard
  ["up"]    = "arrow.up",
  ["down"]  = "arrow.down",
  ["left"]  = "arrow.left",
  ["right"] = "arrow.right",
  -- mouse
  ["1"] = "mouse.left", -- Just map primary button to left button; not always the case, but no simple "get" information.
  ["2"] = "mouse.right",
  ["3"] = "mouse.scroll",
}

local joystickAssetMap = {
  -- buttons
  ["guide"] = "home",
  ["leftstick"]  = "leftstick.press",
  ["rightstick"] = "rightstick.press",
  ["leftshoulder"]  = "leftbutton",
  ["rightshoulder"] = "rightbutton",
  ["dpup"]    = "dpad.up",
  ["dpdown"]  = "dpad.down",
  ["dpleft"]  = "dpad.left",
  ["dpright"] = "dpad.right",
  ["misc1"]    = "NIL",
  ["paddle1"]  = "NIL",
  ["paddle2"]  = "NIL",
  ["paddle3"]  = "NIL",
  ["paddle4"]  = "NIL",
  ["touchpad"] = "NIL", -- if NIL, don't use; we don't have a graphic for it, but it is technically supported
  -- axis
  ["triggerright"] = "righttrigger",
  ["triggerleft"]  = "lefttrigger",
  ["leftx"]  = "leftstick.horizontal",
  ["lefty"]  = "leftstick.vertical",
  ["rightx"] = "rightstick.horizontal",
  ["righty"] = "rightstick.vertical",
}

input.getBindingAssetNames = function(actionName, limit)
  limit = limit or 2
  limit = limit <= 0 and 1 or limit -- ensure it is positive because I am a derp some times

  local controls = settings.client.input

  local action = controls[actionName]
  if not action and actionName ~= "move" then
    logger.warn("Couldn't find action with name: '"..tostring(actionName).."'. Check spelling.")
    return nil
  end

  local lookForJoyStick = input.isGamepadActive()
  local lookForKeyboard = input.isMouseActive()

  if not lookForKeyboard and not lookForJoyStick then
    lookForKeyboard = true
  end

  local assetPrefix, gamepadType
  if lookForKeyboard then
    assetPrefix = "input.pc."
  elseif lookForJoyStick then
    gamepadType = settings.client.gamepadType -- change to other types for testing without needing other controllers
    if gamepadType == "general" then gamepadType = "xbox" end -- the most generic one I've got symbols for
    assetPrefix = ("input.%s."):format(gamepadType)
  end

  if actionName == "move" then
    if lookForKeyboard then -- { key = assetPrefix .. asset, name = asset }
      return { { key = "input.pc.arrows.all", name = actionName } }
    elseif lookForJoyStick then -- It's hardcoded; but who cares
      return { { key = assetPrefix .. "leftstick", name = "leftstick" } }
    end
  end

  -- Priority is the order they are in the array
  local assetNames = { }
  local pattern = "([^:]+):([^:]+)"
  for _, key in ipairs(action) do
    -- attack = { "sc:space", "mouse:1", "button:a", "axis:triggerright+" },
    local keyType, keyValue = key:match(pattern) -- "sc" "space", "mouse" "1", "button" "a", "axis" "triggerright+"
    if keyType and keyValue then
      if lookForKeyboard and (keyType == "sc" or keyType == "mouse") then
        if keyType == "mouse" then
          local asset = keyboardAssetMap[keyValue]
          if not asset then asset = "mouse" end -- generic "mouse" for keys outside of 1-3
          table.insert(assetNames, { key = assetPrefix .. asset, name = asset })
        elseif keyType == "sc" then
          local keyConstant = love.keyboard.getKeyFromScancode(keyValue)
          if keyConstant == "unknown" then
            keyConstant = keyValue -- backup if key doesn't map to system
          end
          local assetKey
          if keyConstant:sub(1, 2) == "kp" then -- keypad, convert to "normal" buttons
            assetKey = keyConstant:sub(3)
          elseif not tonumber(keyConstant) then -- avoid the numerics mapped to mouse
            assetKey = keyboardAssetMap[keyConstant] or keyConstant
          end
          if assetKey and assetKey ~= "NIL" then
            table.insert(assetNames, { key = assetPrefix .. assetKey, name = assetKey })
          end
        end
      elseif lookForJoyStick and (keyType == "button" or keyType == "axis") then
        if keyType == "button" then
          if keyValue == "guide" then
            if gamepadType == "xbox" then keyValue = "360"
            elseif gamepadType == "playstation" then keyValue = "ps4" -- PS4 is most common for PC controllers imo
            elseif gamepadType == "switch" then keyValue = "pro"
            end -- gamepadType == "Steamdeck" then keyValue = "guide" -- guide = guide, not needed; keep for reference 
          end
          keyValue = joystickAssetMap[keyValue] or keyValue
          if keyValue ~= "NIL" then
            table.insert(assetNames, { key = assetPrefix .. keyValue, name = keyValue })
          end
        elseif keyType == "axis" then
          local direction = keyValue:sub(-1) -- -/+ tells us direction
          local axis = keyValue:sub(1, -2)
          local assetKey = joystickAssetMap[axis] or "NIL"
          if assetKey and assetKey ~= "NIL" then
            table.insert(assetNames, { key = assetPrefix .. assetKey, name = assetKey })
          end
        end
      end
    end
    if #assetNames >= limit then
      break
    end
  end

  return #assetNames > 0 and assetNames or nil
end

input.joystickadded = function(joystick)
  if input.gamepad == nil and joystick:getGUID() == settings.client.gamepadGUID then
    input.setGamepad(joystick)
    logger.info("Joystick reconnected!")
  end
end

input.joystickremoved = function(joystick)
  if joystick == input.gamepad then
    input.gamepad = nil
    setBatonJoystick(nil)
  end
end

input.gamepadpressed = function(joystick, ...)
  if joystick ~= input.gamepad then
    input.setGamepad(joystick)
  end
end

input.isGamepadActive = function()
  return input.baton:getActiveDevice() == "joy"
end

input.isMouseActive = function()
  return input.baton:getActiveDevice() == "kbm"
end

local stringsContain = function(pattern, ...)
  for i = 1, select('#', ...) do
    local str = select(i, ...)
    if type(str) == "string" and str:find(pattern) then
      return true
    end
  end
  return false
end

input.setGamepad = function(gamepad)
  if input.gamepad then
    input.gamepad:setPlayerIndex(0)
  end
  input.gamepad = gamepad
  input.gamepad:setPlayerIndex(1)
  setBatonJoystick(input.gamepad)

  local guid = input.gamepad:getGUID()
  if guid == settings.client.gamepadGUID then
    return
  end
  settings.client.gamepadGUID = guid

  local gamepadType = gamepad:getGamepadType()
  local name = gamepad:getName()
  if stringsContain("xbox", gamepadType, name) then
    settings.client.gamepadType = "xbox"
  elseif stringsContain("ps", gamepadType, name) then
    settings.client.gamepadType = "playstation"
  elseif stringsContain("switch", gamepadType, name) or
          stringsContain("joycon", gamepadType, name) then
    settings.client.gamepadType = "switch"
  elseif stringsContain("steamdeck", gamepadType, name) then
    settings.client.gamepadType = "steamdeck"
  else
    settings.client.gamepadType = "general"
  end
  logger.info("Gamepad input, type:", gamepadType, ", interal type:", settings.client.gamepadType)
  love.gamepadswitched(input.joystick, gamepadType, settings.client.gamepadType)
end

if settings.client.gamepadGUID ~= "nil" then
  local joysticks = love.joystick.getJoysticks()
  for _, joystick in ipairs(joysticks) do
    if joystick:getGUID() == settings.client.gamepadGUID then
      input.setGamepad(joystick)
      logger.info("Found previous gamepad via GUID!")
    end
  end
end

return input