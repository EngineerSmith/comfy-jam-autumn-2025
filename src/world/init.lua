local level = require("src.world.level")
local transition = require("src.world.transition")

local player = require("src.player")
local character = require("src.character")

local lfs = love.filesystem

local world = {
  levels = { },
  transitions = { },
  characters = { },
}

world.load = function()
  local chunk, errmsg = lfs.load("assets/level/mapData.lua")
  if not chunk then
    error(errmsg)
    return
  end
  local success, mapData = pcall(chunk)
  if not success then
    error(mapData)
    return
  end

  for levelName, levelInfo in pairs(mapData.levels) do
    world.levels[levelName] = level.new(levelName, levelInfo[1], levelInfo[2], levelInfo[3], levelInfo[4], levelInfo[5])
  end
  for _, transitionInfo in ipairs(mapData.transitions) do
    for edgeName, levelName in pairs(transitionInfo.edgeMap) do
      if world.levels[levelName] then
        transitionInfo.edgeMap[edgeName] = world.levels[levelName]
      else
        logger.warn("Could not find level named '"..tostring(levelName).."'. Check spelling.")
      end
    end
    local t = transition.new(transitionInfo.minX, transitionInfo.minY, transitionInfo.maxX, transitionInfo.maxY, transitionInfo.edgeMap)
    table.insert(world.transitions, t)
  end

  for characterName, characterInfo in pairs(mapData.characters) do
    local chunk, errmsg = lfs.load(characterInfo.file)
    if not chunk then
      error(errmsg)
      return
    end
    local success, character = pcall(chunk)
    if not success then
      error(character)
      return
    end
    local level = world.levels[characterInfo.level]
    if not level then
      logger.warn("Character '"..tostring(characterName).."', level couldn't be found. Check spelling.")
    else
      character:addToLevel(level)
      character:teleport(characterInfo.posX or 0, characterInfo.posY or 0)
    end
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
end

world.update = function(dt)
  player:update(dt)

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

world.draw = function()
  for _, character in pairs(world.characters) do
    character:draw() -- This includes the player character
  end
end

return world