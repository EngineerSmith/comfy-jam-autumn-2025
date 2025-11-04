local level = require("src.world.level")
local transition = require("src.world.transition")

local logger = require("util.logger")
local assetManager = require("util.assetManager")

local g3d = require("libs.g3d")

local prop = require("src.prop")
local player = require("src.player")
local character = require("src.character")
local collectable = require("src.collectable")
local colliderMulti = require("src.colliderMulti")
local colliderCircle = require("src.colliderCircle")
local colliderRectangle = require("src.colliderRectangle")


local lfs = love.filesystem

local world = {
  levels = { },
  transitions = { },
  props = { },
  colliders = { },
  collectables = { },
  characters = { },
  debug = { },

  leaves = 0,
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
  collectable.load() -- load assets

  world.leaves = 0

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
    rect.color = { 1, 1, 0.75, 0.5 }
    table.insert(world.debug, rect)
  end

  for i, modelInfo in ipairs(mapData.models) do
    do
      local model = assetManager[modelInfo.model]
      if not model then
        logger.warn("There was no model prepared with ID: ", tostring(modelInfo.model))
        goto continue
      end
      local texture
      if modelInfo.texture then
        texture = assetManager[modelInfo.texture]
        if not texture then
          logger.warn("There was no texture prepared with ID: ", tostring(modelInfo.texture), ". Attempting to continue.")
        end
      end
      local levelName = modelInfo.level
      if type(levelName) ~= "string" then
        logger.warn("MapData's Model["..i.."] is missing level.")
        goto continue
      end
      local level = world.levels[levelName]
      if not level then
        logger.warn("MapData's Model["..i.."] had level not found. Check spelling: "..tostring(levelName))
        goto continue
      end
      levelName = nil
      local x, y, z, scale = modelInfo.x, modelInfo.y, modelInfo.z, modelInfo.scale or 1
      local collider
      if modelInfo.collider then
        local colliderInfo = modelInfo.collider
        local levels = { }
        for _, levelName in ipairs(colliderInfo.levels) do
          if world.levels[levelName] then
            table.insert(levels, world.levels[levelName])
          else
            logger.warn("MapData's Model["..i.."]'s collider had level that wasn't found. Check spelling: "..tostring(levelName))
          end
        end
        if #levels == 0 then
          logger.warn("MapData's Model["..i.."]'s collider had no valid levels, ignoring. Model will appear without collider.")
        else
          if colliderInfo.shape == "rectangle" then
            local width, height, tag = colliderInfo.width, colliderInfo.height, colliderInfo.tag
            width, height = width * scale, height * scale
            local halfWidth, halfHeight = width / 2, height / 2
            collider = colliderRectangle.new(x-halfWidth, y-halfHeight, width, height, tag, levels)
          elseif colliderInfo.shape == "circle" then
            local radius, segments, rotation, tag = colliderInfo.radius, colliderInfo.segments, colliderInfo.rotation, colliderInfo.tag
            radius = radius * scale
            collider = colliderCircle.new(x, y, radius, segments, rotation, tag, levels)
          elseif colliderInfo.shape == "multi" then
            local tag = colliderInfo.tag
            collider = colliderMulti.new(x, y, scale, colliderInfo, tag, levels)
          else
            logger.warn("MapData's Model["..i.."]'s collider had invalid shape. Check spelling: ", tostring(colliderInfo.shape))
          end
        end
      end

      local newProp = prop.new(model, texture, x, y, z, level, scale, collider)
      if modelInfo.rx or modelInfo.ry or modelInfo.rz then
        local rx, ry, rz = modelInfo.rx, modelInfo.ry, modelInfo.rz
        newProp:setRotation(rx, ry, rz)
      end
      if modelInfo.noScaleZ then
        newProp:setNoScaleZ(true)
      end
      table.insert(world.props, newProp)
    end
    ::continue::
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
        local radius, segments, rotation = colliderInfo.radius, colliderInfo.segments, colliderInfo.rotation
        collider = colliderCircle.new(x, y, radius, segments or 16, rotation, tag, levels)
      elseif colliderInfo.shape == "multi" then
          local tag = colliderInfo.tag
          collider = colliderMulti.new(x, y, 1, colliderInfo, tag, levels)
      else
        logger.warn("There is a collider with bad shape. mapData.colliders["..tostring(i).."]. Shape given: "..tostring(colliderInfo.shape))
      end
      if collider then
        if type(colliderInfo.rz) == "number" then
          collider:rotate(colliderInfo.rz)
        end
        table.insert(world.colliders, collider)
      end
    end
  end

  for i, collectableInfo in ipairs(mapData.collectables) do
    local level = world.levels[collectableInfo.level]
    if not level then
      logger.warn("Collectable of mapData.collectables["..tostring(i).."] had invalid level. Check spelling. Ignoring collectable.")
    else
      local x, y, tag = collectableInfo.x, collectableInfo.y, collectableInfo.tag
      table.insert(world.collectables, collectable.new(x, y, level, tag))
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
  collectable.unload()

  world.levels = { }
  world.transitions = { }
  world.props = { }
  world.colliders = { }
  world.collectables = { }
  world.characters = { }
  world.debug = { }
end

local COLLECTABLE_SHADOW_MAX = 32
local sort_ClosestMag = function(a, b)
  return a.mag < b.mag
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

  local playerCharacter = player.character
  if playerCharacter then
    local collectablePositions = { }
    for _, collectable in ipairs(world.collectables) do
      if not collectable.isCollected then
        local dx = collectable.x - playerCharacter.x
        local dy = collectable.y - playerCharacter.y
        local mag = math.sqrt(dx * dx + dy * dy)

        table.insert(collectablePositions, {
          mag = mag,
          collectable:getShadowPosition() -- multiple return
        })
      end
    end

    table.sort(collectablePositions, sort_ClosestMag)

    if #collectablePositions > COLLECTABLE_SHADOW_MAX then
      for i = #collectablePositions, COLLECTABLE_SHADOW_MAX + 1, -1 do
        table.remove(collectablePositions, i)
      end
    end

    local shader = g3d.shader
    if #collectablePositions > 0 then
      shader:send("collectablePositions", unpack(collectablePositions))
      shader:send("numCollectable", #collectablePositions)
    else
      shader:send("numCollectable", 0)
    end

    for _, collectable in ipairs(world.collectables) do
      collectable:update(dt)

      if not collectable.isCollected and playerCharacter:isInLevel(collectable.level) then
        local dx, dy = collectable.x - playerCharacter.x, collectable.y - playerCharacter.y
        local mag = math.sqrt(dx * dx + dy * dy)
        local playerRadius = playerCharacter.halfSize * playerCharacter.textureSizeMod
        local distance = mag - playerRadius

        if distance <= 1 then
          local t = 1.0 - math.min(1.0, distance / 1)
          collectable.scale = (1 - t) * 1 + t * 0.5
        end

        if distance <= .1 then -- .1 for jiggle room
          local value = collectable:collected()
          world.leaves = world.leaves + value
        elseif distance <= player.magnet * playerCharacter.size then
          local dx, dy = dx / mag, dy / mag
          local speed = 1.5
          if distance <= (player.magnet * playerCharacter.size)/2 then
            speed = 4
          end
          collectable.x = collectable.x + -dx * speed * dt
          collectable.y = collectable.y + -dy * speed * dt
        end
      else
        collectable.scale = 1
      end
    end
  end
end

local lg = love.graphics
world.debugDraw = function()
  lg.push()
  for _, rect in ipairs(world.debug) do
    lg.setColor(rect.color)
    lg.rectangle("fill", unpack(rect))
  end
  for _, collider in ipairs(world.colliders) do
    collider:debugDraw()
  end
  for _, prop in ipairs(world.props) do
    if prop.collider then
      prop.collider:debugDraw()
    end
  end
  for _, collectable in ipairs(world.collectables) do
    collectable:debugDraw()
  end
  player.character:debugDraw()
  lg.pop()
end

world.draw = function()
  lg.setColor(1,1,1,1)

  for _, prop in ipairs(world.props) do
    prop:draw()
  end

  for _, collectable in ipairs(world.collectables) do
    collectable:draw()
  end

  for _, character in pairs(world.characters) do
    character:draw() -- This includes the player character
  end

  lg.push("all")
    lg.origin()
    lg.setColor(1,1,1,1)
    lg.print(("Collected Leaves: %2d"):format(world.leaves), 20, 20)
  lg.pop()
end

return world