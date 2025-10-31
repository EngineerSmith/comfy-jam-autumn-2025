local level = require("src.world.level")
local transition = require("src.world.transition")

local logger = require("util.logger")

local player = require("src.player")
local character = require("src.character")
local colliderCircle = require("src.colliderCircle")
local colliderRectangle = require("src.colliderRectangle")

local lfs = love.filesystem

local world = {
  levels = { },
  transitions = { },
  colliders = { },
  characters = { },
  debug = { },
}

local characterFactories = { }
local getCharacterFactory = function(file)
  if characterFactories[file] then
    return characterFactories[file]
  end

  local chunk, errmsg = lfs.load(file)
  if not chunk then
    error(errmsg)
    return
  end
  local success, characterFactory = pcall(chunk)
  if not success then
    error(characterFactory)
    return
  end

  if type(characterFactory) ~= "function" then
    error("Character factory didn't return function: "..tostring(file))
    return
  end

  characterFactories[file] = characterFactory
  return characterFactory
end

world.load = function()
  local mapData
  do -- Load mapData
    local chunk, errmsg = lfs.load("assets/level/mapData.lua")
    if not chunk then
      error(errmsg)
      return
    end
    local success
    success, mapData = pcall(chunk)
    if not success then
      error(mapData)
      return
    end
  end

  for levelName, levelInfo in pairs(mapData.levels) do
    local x, y, z, width, height = levelInfo.x, levelInfo.y, levelInfo.z, levelInfo.width, levelInfo.height
    world.levels[levelName] = level.new(levelName, x, y, width, height, z)
    local rect = { unpack(world.levels[levelName].rect) }
    rect.color = { 1, 1, 1, 0.5 }
    table.insert(world.debug, rect)
  end
  for _, transitionInfo in ipairs(mapData.transitions) do
    for edgeName, levelName in pairs(transitionInfo.edgeMap) do
      if world.levels[levelName] then
        transitionInfo.edgeMap[edgeName] = world.levels[levelName]
      else
        logger.warn("Could not find level named '"..tostring(levelName).."'. Check spelling.")
      end
    end
    local x, y, width, height = transitionInfo.x, transitionInfo.y, transitionInfo.width, transitionInfo.height
    local t = transition.new(x, y, width, height, transitionInfo.edgeMap)
    table.insert(world.transitions, t)
    local rect = { unpack(t.rect) }
    rect.color = { 1, 1, 0, 0.5 }
    table.insert(world.debug, rect)
  end

  for i, colliderInfo in ipairs(mapData.colliders) do

    local levels = { }
    for _, levelName in ipairs(colliderInfo.levels) do
      if world.levels[levelName] then
        table.insert(levels, world.levels[levelName])
      else
        logger.warn("Couldn't find level: '"..tostring(levelName)..".' Check spelling of mapData.colliders["..tostring(i).."]")
      end
    end

    if #levels == 0 then
      logger.warn("Collider of mapData.colliders["..tostring(i).."] had no valid levels, ignoring.")
    else
      local x, y, tag = colliderInfo.x, colliderInfo.y, colliderInfo.tag
      local collider
      if colliderInfo.shape == "rectangle" then
        local width, height = colliderInfo.width, colliderInfo.height
        collider = colliderRectangle.new(x, y, width, height, tag, levels)
      elseif colliderInfo.shape == "circle" then
        local radius, segments = colliderInfo.radius, colliderInfo.segments
        collider = colliderCircle.new(x, y, radius, segments or 16, tag, levels)
      else
        logger.warn("There is a collider with bad shape. mapData.colliders["..tostring(i).."]. Shape given: "..tostring(colliderInfo.shape))
      end
      if collider then
        table.insert(world.colliders, collider)
      end
    end
  end

  for characterName, characterInfo in pairs(mapData.characters) do
    local character = getCharacterFactory(characterInfo.file)()
    local level = world.levels[characterInfo.level]
    if not level then
      logger.warn("Character '"..tostring(characterName).."', level couldn't be found. Check spelling.")
    else
      character:addToLevel(level)
      character:teleport(characterInfo.x or 0, characterInfo.y or 0)
    end
    character.name = characterName
    world.characters[characterName] = character
  end

  local playerCharacter = world.characters[mapData.playerCharacter]
  if not playerCharacter then
    logger.warn("Couldn't find player character, '"..tostring(mapData.playerCharacter).."'. Check spelling.")
  else
    player.setCharacter(playerCharacter)
  end
end

world.unload = function()
  world.levels = { }
  world.transitions = { }
  world.colliders = { }
  world.characters = { }
  world.debug = { }
end

world.update = function(dt)
  player.update(dt)

  for _, character in pairs(world.characters) do
    character:update(dt)
  end

  for _, level in pairs(world.levels) do
    level:update(dt)
  end
  for _, transition in ipairs(world.transitions) do
    transition:update(world.characters)
  end
end

local lg = love.graphics
world.draw = function()
  for _, rect in ipairs(world.debug) do
    lg.setColor(rect.color)
    lg.rectangle("fill", unpack(rect))
  end
  for _, collider in ipairs(world.colliders) do
    collider:draw()
  end
  lg.setColor(1,1,1,1)

  for _, character in pairs(world.characters) do
    character:draw() -- This includes the player character
  end
end

return world