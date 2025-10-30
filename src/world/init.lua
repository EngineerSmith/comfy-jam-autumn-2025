local level = require("src.world.level")
local transition = require("src.world.transition")

local player = require("src.player")
local character = require("src.character")

local lfs = love.filesystem

local world = {
  levels = { },
  transitions = { },
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
    local x, y, width, height, z = unpack(levelInfo)
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
    local x, y, width, height = unpack(transitionInfo)
    local t = transition.new(x, y, width, height, transitionInfo.edgeMap)
    table.insert(world.transitions, t)
    local rect = { unpack(t.rect) }
    rect.color = { 1, 1, 0, 0.5 }
    table.insert(world.debug, rect)
  end

  for characterName, characterInfo in pairs(mapData.characters) do
    local character = getCharacterFactory(characterInfo.file)()
    local level = world.levels[characterInfo.level]
    if not level then
      logger.warn("Character '"..tostring(characterName).."', level couldn't be found. Check spelling.")
    else
      character:addToLevel(level)
      character:teleport(characterInfo.posX or 0, characterInfo.posY or 0)
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
  lg.setColor(1,1,1,1)

  for _, character in pairs(world.characters) do
    character:draw() -- This includes the player character
  end
end

return world