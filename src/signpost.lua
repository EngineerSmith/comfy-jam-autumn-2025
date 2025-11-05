local lg = love.graphics

local signpost = { }
signpost.__index = signpost

local g3d = require("libs.g3d")

local ui = require("util.ui")
local input = require("util.input")
local assetManager = require("util.assetManager")

local zone = require("src.zone")
local player = require("src.player")

local CANVAS_WIDTH, CANVAS_HEIGHT = 1024 + 256, 512
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


local parseContent = function(rawContent)
  segments = { }
  local pattern = "%[([^%]]+)%]" -- matches test inside [tags]
  local lastEnd = 1

  local tagStart, tagEnd, tagContent = rawContent:find(pattern, lastEnd)
  while tagStart do
    local textPrefix = rawContent:sub(lastEnd, tagStart - 1)
    if #textPrefix > 0 then
      table.insert(segments, { type = "text", value = textPrefix })
    end

    local parts = { }
    for part in tagContent:gmatch("([^%.]+)") do
      table.insert(parts, part)
    end

    local tagType = parts[1]
    local tagKey = parts[2]
    
    if tagType and tagKey then
      table.insert(segments, { type = "tag", tag = tagType, key = tagKey })
    end

    lastEnd = tagEnd + 1
    tagStart, tagEnd, tagContent = rawContent:find(pattern, lastEnd)
  end

  local trailingText = rawContent:sub(lastEnd)
  if #trailingText > 0 then
    table.insert(segments, { type = "text", value = trailingText })
  end

  return segments
end

signpost.new = function(x, y, z, radius, rotation, content, level)
  local self = setmetatable({
    x = x, y = y, z = z or 0,
    radius = radius or 5,
    rotation = rotation or 0,
    content = content,
    level = level,
    fade = 0.0,
    assetCache = { }, -- assetKeys it has a reference to
  }, signpost)
  self:setState("hide")
  self.segments = parseContent(self.content)
  return self
end

local lerp = function(a, b, t)
  return a + (b - a) * t
end

signpost.unload = function(self)
  for assetKey in pairs(self.assetCache) do
    assetManager.unload(assetKey) -- reduces reference count
  end
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

-- TODO replace placeholder with information
local getCollectableDisplay = function(zoneName)
  return zone.prettyPrint(zoneName)
end

local handleButtonTag = function(actionName)
  local assetNames = input.getBindingAssetNames(actionName, 2)
  if assetNames then
    return assetNames
  end
  return { } -- If it fails, uh do something. TODO
end

local processSegment = function(segment)
  if segment.type == "text" then
    return { type = "text", content = segment.value }
  elseif segment.type == "tag" then
    if segment.tag == "button" then
      return { type = "button", content = handleButtonTag(segment.key) }
    elseif segment.tag == "collectable_count" then
      return { type = "collectable_count", content = getCollectableDisplay(segment.key) }
    end
  end
  return { type = "text", content = "ERR;TYPE:"..tostring(segment.type) }
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

  local shouldRecalculate = false

  local currentDevice = input.isGamepadActive() or "kbm"

  if self.state ~= "hide" then
    if self.activeDevice ~= currentDevice or not self.progressedSegments then
      self.activeDevice = currentDevice
      shouldRecalculate = true
    end
  end

  if shouldRecalculate then
    local processedSegments = { }
    local touched = { } -- tracks assets currently used by processedSegments
    local loadKeys = { } -- Assets that need loading this frame
    local isBlockContent = false -- Check if block content (like `collectable_count`) is present

    for _, segment in ipairs(self.segments) do
      local processed = processSegment(segment)

      if processed.type == "collectable_count" then
        isBlockContent = true
      end

      if processed.type == "button" then
        for _, assetInfo in ipairs(processed.content) do
          touched[assetInfo.key] = true
          if not self.assetCache[assetInfo.key] then
            table.insert(loadKeys, assetInfo.key)
            self.assetCache[assetInfo.key] = true
          end
        end
      end

      table.insert(processedSegments, processed)
    end

    self.processedSegments = processedSegments
    self.isBlockContent = isBlockContent

    -- Load new assets
    if #loadKeys > 0 then
      assetManager.load(loadKeys)
    end

    -- Unload old assets
    local keysToRemove = { }
    for assetKey in pairs(self.assetCache) do
      if not touched[assetKey] then -- asset no longer in use
        table.insert(keysToRemove, assetKey)
      end
    end

    if #keysToRemove > 0 then
      assetManager.unload(keysToRemove) -- Reduce reference count of all keys
      for _, key in ipairs(keysToRemove) do
        self.assetCache[key] = nil
      end
    end
  end
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

local GLYPH_BUTTON_SCALE = 1
local GLYPH_BUTTON_WIDTH  = 64
local GLYPH_BUTTON_HEIGHT = 64
local BOX_PADDING = 40
local SEGMENT_GAP = 20

local getSegmentsDimensions = function(segments, font)
  local totalWidth = 0
  local contentHeight = 0
  local lineHeight = font:getHeight()
  local isBlockContent = false
  local blockContentMaxW = 0
  local segmentsToProcess = { }

  for _, segment in ipairs(segments) do
    if segment.type == "collectable_count" then
      isBlockContent = true
      for _, line in ipairs(segment.content) do
        blockContentMaxW = math.max(blockContentMaxW, font:getWidth(line))
      end
      contentHeight = math.max(contentHeight, lineHeight * #segment.content)
      break -- we break early here because collect_count should *always* be the only thing drawn
    else
      table.insert(segmentsToProcess, segment)
    end
  end

  -- Only calculate inline metrics if not block content
  for _, segment in ipairs(segmentsToProcess) do
    if segment.type == "text" then
      totalWidth = totalWidth + font:getWidth(segment.content)
      contentHeight = math.max(contentHeight, lineHeight)
    elseif segment.type == "button" then
      local innerPadding = 16
      local buttonSequenceWidth = 0
      local maxButtonHeight = 0

      for i, assetInfo in ipairs(segment.content) do
        local asset = assetManager[assetInfo.key]
        local w, h
        if asset then -- has asset loaded
          w, h = asset:getDimensions()
        else
          w, h = GLYPH_BUTTON_WIDTH, GLYPH_BUTTON_HEIGHT
        end
        w, h = w * GLYPH_BUTTON_SCALE, h * GLYPH_BUTTON_SCALE

        buttonSequenceWidth = buttonSequenceWidth + w + (i > 1 and innerPadding or 0) -- internal padding between
        maxButtonHeight = math.max(maxButtonHeight, h)
      end
      totalWidth = totalWidth + buttonSequenceWidth
      contentHeight = math.max(contentHeight, maxButtonHeight)
    end
  end

  if not isBlockContent and #segmentsToProcess > 1 then
    totalWidth = totalWidth + (#segmentsToProcess - 1) * SEGMENT_GAP
  end
  
  if isBlockContent then
    totalWidth = blockContentMaxW
  end

  -- Ensure a minimum height if only text is present
  contentHeight = math.max(contentHeight, lineHeight)

  return totalWidth, contentHeight, lineHeight
end

local drawSegment = function(segment, font, xOffset, yOffset, maxLineHeight, maxTotalWidth)
  local w, h = 0, 0

  lg.push("all")
  lg.setColor(1,1,1,1)

  if segment.type == "text" then
    local textWidth = font:getWidth(segment.content)
    local textHeight = font:getHeight()
    local yAlignmentOffset = math.floor((maxLineHeight - textHeight) / 2)

    lg.print(segment.content, font, xOffset, yOffset + yAlignmentOffset)

    w, h = textWidth, textHeight
  elseif segment.type == "button" then
    local innerPadding = 16
    local buttonSequenceWidth = 0
    local maxButtonHeight = 0

    for _, assetInfo in ipairs(segment.content) do
      local asset = assetManager[assetInfo.key]
      local _, assetHeight
      if asset then
        _, assetHeight = asset:getDimensions()
      else
        _, assetHeight = GLYPH_BUTTON_WIDTH, GLYPH_BUTTON_HEIGHT
      end
      maxButtonHeight = math.max(maxButtonHeight, assetHeight * GLYPH_BUTTON_SCALE)
    end

    local containerHeight = maxButtonHeight
    local yAlignmentOffset = math.floor((maxLineHeight - containerHeight) / 2)

    local buttonYStart = yOffset + yAlignmentOffset

    for i, assetInfo in ipairs(segment.content) do
      local asset = assetManager[assetInfo.key]
      local assetWidth, assetHeight
      if asset then
        lg.draw(asset, xOffset, buttonYStart, 0, GLYPH_BUTTON_SCALE)
        assetWidth, assetHeight = asset:getDimensions()
      else
        assetWidth, assetHeight = GLYPH_BUTTON_WIDTH, GLYPH_BUTTON_HEIGHT
      end

      assetWidth, assetHeight = assetWidth * GLYPH_BUTTON_SCALE, assetHeight * GLYPH_BUTTON_SCALE
      local width = assetWidth + (i > 1 and innerPadding or 0)

      if i > 1 then
        local lineCentreX = xOffset + innerPadding / 2
        local lineLength = containerHeight * 0.75

        local lineY1 = buttonYStart + (containerHeight - lineLength) / 2
        local lineY2 = lineY1 + lineLength

        lg.push("all")
        lg.setColor(1,1,1, 0.6)
        lg.setLineWidth(3)
        lg.line(lineCentreX, lineY1, lineCentreX, lineY2)
        lg.pop()

        xOffset = xOffset + innerPadding
      end

      xOffset = xOffset + assetWidth
      buttonSequenceWidth = buttonSequenceWidth + width
    end

    w = buttonSequenceWidth
    h = maxLineHeight
  elseif segment.type == "collectable_count" then
    local lines = segment.content
    local lineHeight = font:getHeight()
    local currentY = yOffset

    for _, line in ipairs(lines) do
      local lineW = font:getWidth(line)
      local lineStartX = xOffset + (maxTotalWidth - lineW) / 2

      lg.print(line, font, lineStartX, currentY)
      currentY = currentY + lineHeight
    end

    w = maxTotalWidth
    h = lineHeight * #lines
  end
  lg.pop()
  return w, h
end

-- Ensure signpost is drawn last with transparent textures
signpost.draw = function(self)
  if self.state == "hide" or not self.processedSegments then
    return
  end

  lg.push("all")
  lg.setCanvas(signpostCanvas)
  lg.clear(0,0,0,0)

  local font = ui.getFont(68, "fonts.regular.bold") -- todo

  local totalWidth, contentHeight, lineHeight = getSegmentsDimensions(self.processedSegments, font)

  local boxWidth = math.min(totalWidth + BOX_PADDING * 2, CANVAS_WIDTH)
  local boxHeight = contentHeight + BOX_PADDING * 2

  local startX = math.floor(CANVAS_WIDTH  / 2 - boxWidth  / 2)
  local startY = math.floor(CANVAS_HEIGHT / 2 - boxHeight / 2)

  lg.setColor(.1,.1,.1, .7)
  lg.rectangle("fill", startX, startY, boxWidth, boxHeight, 16)
  -- print(startX, startY, boxWidth, boxHeight, ">>>>", CANVAS_WIDTH, CANVAS_HEIGHT)

  if self.isBlockContent then
    local textY = startY + BOX_PADDING
    for _, segment in ipairs(self.processedSegments) do
      if segment.type == "collectable_count" then
        drawSegment(segment, font, startX + BOX_PADDING, textY, contentHeight, totalWidth)
        break
      end
    end
  else
    local currentX = math.floor(CANVAS_WIDTH / 2 - totalWidth  / 2)
    local textY = math.floor(CANVAS_HEIGHT / 2 - contentHeight / 2)

    for i, segment in ipairs(self.processedSegments) do
      local segmentWidth, _ = drawSegment(segment, font, currentX, textY, contentHeight, totalWidth)
      currentX = currentX + segmentWidth
      if i < #self.processedSegments then
        currentX = currentX + SEGMENT_GAP
      end
    end
  end

  lg.pop()

  -- Draw 3D model with fade
  lg.push("all")
  lg.setColor(1,1,1, self.fade)
  signpostModel:setTranslation(self.x, self.y, self.z + self.level.zLevel)
  signpostModel:setRotation(-math.rad(20), 0, self.rotation)
  signpostModel:draw()
  lg.pop()
end

return signpost