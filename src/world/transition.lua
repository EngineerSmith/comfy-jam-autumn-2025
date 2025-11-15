local transition = { }
transition.__index = transition

local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

local logger = require("util.logger")

transition.new = function(x, y, width, height, edgeMap)
  local minX, minY = x, y
  local maxX, maxY = x + width, y + height
  if minX > maxX then minX, maxX = maxX, minX end
  if minY > maxY then minY, maxY = maxY, minY end

  local self = setmetatable({
    minX = minX, minY = minY,
    maxX = maxX, maxY = maxY,
    -- edgeMap: E.G. { left = levelA, right = levelB, top = nil, bottom = nil }
    edgeMap = edgeMap or { },
    rect = { x, y, width, height },
    walls = { },
  }, transition)

  self.levels = { }
  local addedLevels = { }
  for _, level in pairs(self.edgeMap) do
    if level and not addedLevels[level] then
      table.insert(self.levels, level)
      addedLevels[level] = true
    end
  end

  self.isRampX = self.edgeMap.left and self.edgeMap.right -- Horizontal transition
  self.isRampY = self.edgeMap.top and self.edgeMap.bottom -- Vertical   transition

  if #self.levels > 0 then -- Don't create walls for a boxed in transition zone
    self:createWalls()
  end
  return self
end

local idCounter = 0
local getWallID = function(edgeName)
  idCounter = idCounter + 1
  return "TransitionWall_"..edgeName.."_"..idCounter
end

local wallDepth = 0.1 -- increase depth if there is jitter and phasing through walls, ideal starting values: 1, 2
local cornerRadius = 0.1
transition.createWalls = function(self)
  local minX, minY, maxX, maxY = self.minX, self.minY, self.maxX,  self.maxY
  local halfDepth = wallDepth / 2
  local shapes = { }

  local totalWidth = maxX - minX
  local totalHeight = maxY - minY
  local centreX = minX + totalWidth / 2
  local centreY = minY + totalHeight / 2

  local lengthReduction = 2 * cornerRadius

  local maxRX = halfDepth + totalWidth / 2
  local maxRY = halfDepth + totalHeight / 2

  -- Top Wall
  if not self.edgeMap.top then
    local wallWidth = totalWidth - lengthReduction
    local rY = -maxRY
    if wallWidth > 0 then
      local shape = slick.newRectangleShape(- wallWidth / 2, rY - halfDepth / 2, wallWidth, wallDepth, slickHelper.tags.WALL)
      table.insert(shapes, shape)
    end
  end
  -- Bottom Wall
  if not self.edgeMap.bottom then
    local wallWidth = totalWidth - lengthReduction
    local rY = maxRY
    if wallWidth > 0 then
      local shape = slick.newRectangleShape(- wallWidth / 2, rY - halfDepth / 2, wallWidth, wallDepth, slickHelper.tags.WALL)
      table.insert(shapes, shape)
    end
  end
  -- Left Wall
  if not self.edgeMap.left then
    local wallHeight = totalHeight - lengthReduction
    local rX = -maxRX
    if wallHeight > 0 then
      local shape = slick.newRectangleShape(rX - halfDepth, - wallHeight / 2, wallDepth, wallHeight, slickHelper.tags.WALL)
      table.insert(shapes, shape)
    end
  end
  -- Right Wall
  if not self.edgeMap.right then
    local wallHeight = totalHeight - lengthReduction
    local rX = maxRX
    if wallHeight > 0 then
      local shape = slick.newRectangleShape(rX - halfDepth, - wallHeight / 2, wallDepth, wallHeight, slickHelper.tags.WALL)
      table.insert(shapes, shape)
    end
  end
  -- Top Left Corner
  if not self.edgeMap.top or not self.edgeMap.left then
    local rX, rY = -maxRX, -maxRY
    local shape = slick.newCircleShape(rX, rY, cornerRadius, nil, slickHelper.tags.WALL)
    table.insert(shapes, shape)
  end
  -- Top Right Corner
  if not self.edgeMap.top or not self.edgeMap.right then
    local rX, rY = maxRX, -maxRY
    local shape = slick.newCircleShape(rX, rY, cornerRadius, nil, slickHelper.tags.WALL)
    table.insert(shapes, shape)
  end
  -- Bottom Left Corner
  if not self.edgeMap.bottom or not self.edgeMap.left then
    local rX, rY = -maxRX, maxRY
    local shape = slick.newCircleShape(rX, rY, cornerRadius, nil, slickHelper.tags.WALL)
    table.insert(shapes, shape)
  end
  -- Bottom Right Corner
  if not self.edgeMap.bottom or not self.edgeMap.right then
    local rX, rY = maxRX, maxRY
    local shape = slick.newCircleShape(rX, rY, cornerRadius, nil, slickHelper.tags.WALL)
    table.insert(shapes, shape)
  end

  if #shapes > 0 then
    local shapeGroup = slick.newShapeGroup(unpack(shapes))
    local groupID = getWallID("group")
    for _, level in ipairs(self.levels) do
      level:add(groupID, centreX, centreY, shapeGroup)
    end
    table.insert(self.walls, groupID)
  end
end

transition.removeWalls = function(self)
  if not self.walls or #self.walls == 0 then
    return
  end
  for _, wallID in ipairs(self.walls) do
    for _, level in ipairs(self.levels) do
      level:remove(wallID)
    end
  end
  self.walls = { }
end

transition.isInside = function(self, x, y)
  return x > self.minX and x < self.maxX and
         y > self.minY and y < self.maxY
end

transition.checkExitEdge = function(self, character)
  local edgeName
  if     character.y < self.minY and character.previousY >= self.minY then
    edgeName = "bottom"
  elseif character.y > self.maxY and character.previousY <= self.maxY then
    edgeName = "top"
  elseif character.x < self.minX and character.previousX >= self.minX and
         character.y > self.minY and character.y < self.maxY then
    edgeName = "left"
  elseif character.x > self.maxX and character.previousX <= self.maxX and
         character.y > self.minY and character.y < self.maxY then
    edgeName = "right"
  end
  return type(edgeName) == "string" and self.edgeMap[edgeName], edgeName
end

transition.update = function(self, characters)
  if #self.levels <= 1 then -- transition is a dead end, so no logic needed (2 levels minimally needed)
    return
  end

  for _, character in pairs(characters) do
    local inside = self:isInside(character.x, character.y)
    local wasInside = self:isInside(character.previousX, character.previousY)
    
    -- Check if character isn't within transition zone; skip
    if not inside and not wasInside then
      goto continue
    end

    -- Check how many of the ramp's levels the character is currently in.
    local levelsAssociated = 0
    for _, level in ipairs(self.levels) do
      if level:isInLevel(character) then
        levelsAssociated = levelsAssociated + 1
      end
    end
    if levelsAssociated == 0 then
      goto continue
    end

    if inside then
      character.z = self:calculateZ(character)
    end

    if inside then 
      -- If entered, add to all levels they're aren't in
        -- This happens constantly while they're inside the transition zone due to
        -- the bug of transitions zones being created on top of a character.
      for _, level in ipairs(self.levels) do
        if not level:isInLevel(character) then
          character:addToLevel(level)
        end
      end
    elseif not inside and wasInside and levelsAssociated > 1 then -- Exited
      -- Once exited remove from all levels, but the one they choose
      local targetLevel, edgeName = self:checkExitEdge(character)
      if not targetLevel then
        logger.warn("Character exited transitions, but didn't trigger edge exit")
        goto continue
      end

      for _, level in ipairs(self.levels) do
        if level ~= targetLevel then
          character:removeFromLevel(level)
        end
      end

      local scriptingEngine = require("src.scripting")
      scriptingEngine.startScript("event.enter."..targetLevel.name)
    end
    ::continue::
  end
end

local lerp = function(a, b, t)
  return a + (b - a) * t
end

transition.calculateZ = function(self, character)
  if #self.levels == 0 then return 0 end
  if #self.levels ~= 2 then
    return self.levels[1].zLevel -- All levels must be on the same zLevel for other transitions
  end
  local z1, z2 = self.levels[1].zLevel, self.levels[2].zLevel
  local t = 0

  if self.isRampX then
    local startZ, endZ = z1, z2 -- start with the assumption left == levels[1]
    if self.edgeMap.left == self.levels[2] then
      startZ, endZ = z2, z1
    end

    local range = self.maxX - self.minX
    t = (character.x - self.minX) / range

    return lerp(startZ, endZ, t)
  elseif self.isRampY then
    local startZ, endZ = z1, z2
    if self.edgeMap.bottom == self.levels[2] then
      startZ, endZ = z2, z1
    end

    local range = self.maxY - self.minY
    t = (character.y - self.minY) / range

    return lerp(startZ, endZ, t)
  end

  -- Shouldn't reach this point
  return character.z
end

return transition