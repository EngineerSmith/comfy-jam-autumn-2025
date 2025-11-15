local nest = require("src.world.nest")
local level = require("src.world.level")
local transition = require("src.world.transition")

local logger = require("util.logger")
local assetManager = require("util.assetManager")

local g3d = require("libs.g3d")

local prop = require("src.prop")
local player = require("src.player")
local signpost = require("src.signpost")
local character = require("src.character")
local smashable = require("src.smashable")
local collectable = require("src.collectable")
local interaction = require("src.interaction")
local musicPlayer = require("src.musicPlayer")
local scriptingEngine = require("src.scripting")
local colliderMulti = require("src.colliderMulti")
local colliderCircle = require("src.colliderCircle")
local colliderRectangle = require("src.colliderRectangle")


local lfs = love.filesystem

local world = {
  levels = { },
  transitions = { },
  props = { },
  specialProps = { },
  colliders = { },
  collectables = { },
  smashables = { },
  signposts = { },
  interactions = { },
  characters = { },
  debug = { },

  leaves = 0,
  stage = "world",
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
  smashable.load()

  world.leaves = 0
  world.currencyLeaves = 0

  -- local mapData
  -- do -- Load mapData
  --   local chunk, errmsg = lfs.load("assets/level/mapData.lua")
  --   if not chunk then
  --     error(errmsg)
  --     return
  --   end
  --   local success
  --   success, mapData = pcall(chunk)
  --   if not success then
  --     error(mapData)
  --     return
  --   end
  -- end
  -- The above was causing issues with how `helper` rng was being seeded, and the wrong assets were being loaded, have to rely on require to cache the correct asset list
  local mapData = require("assets.level.mapData")

  for levelName, levelInfo in pairs(mapData.levels) do
    local x, y, z, width, height = levelInfo.x, levelInfo.y, levelInfo.z, levelInfo.width, levelInfo.height
    world.levels[levelName] = level.new(levelName, x, y, width, height, z)
    local rect = { unpack(world.levels[levelName].rect) }
    rect.color = { 1, 1, 1, 0.5 }
    -- if levelName == "zone1.rock" then
    table.insert(world.debug, rect)
    -- end
  end

  for _, transitionInfo in ipairs(mapData.transitions) do
    local x, y, width, height = transitionInfo.x, transitionInfo.y, transitionInfo.width, transitionInfo.height
    world.addTransition(x, y, width, height, transitionInfo.edgeMap)
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
            local xOffset, yOffset = colliderInfo.x or 0, colliderInfo.y or 0
            xOffset, yOffset = xOffset * scale, yOffset * scale
            local width, height, tag = colliderInfo.width, colliderInfo.height, colliderInfo.tag
            width, height = width * scale, height * scale
            local halfWidth, halfHeight = width / 2, height / 2
            collider = colliderRectangle.new(x, y, width, height, tag, levels, -halfWidth+xOffset, -halfHeight+yOffset)
          elseif colliderInfo.shape == "circle" then
            local radius, segments, rotation, tag = colliderInfo.radius, colliderInfo.segments, colliderInfo.rotation, colliderInfo.tag
            radius = radius * scale
            local cx, cy = colliderInfo.x or 0, colliderInfo.y or 0
            cx, cy = cx * scale, cy * scale
            collider = colliderCircle.new(x + cx, y + cy, radius, segments, rotation, tag, levels)
          elseif colliderInfo.shape == "multi" then
            local tag = colliderInfo.tag
            collider = colliderMulti.new(x, y, scale, colliderInfo, tag, levels)
          else
            logger.warn("MapData's Model["..i.."]'s collider had invalid shape. Check spelling: ", tostring(colliderInfo.shape))
          end
        end
      end

      if collider and modelInfo.onBonkScriptID then
        collider.onBonkScriptID = modelInfo.onBonkScriptID
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

      if modelInfo.id then
        world.specialProps[modelInfo.id] = newProp
      end
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
      local x, y, tag, zone = collectableInfo.x, collectableInfo.y, collectableInfo.tag, collectableInfo.zone
      table.insert(world.collectables, collectable.new(x, y, level, tag, zone, collectableInfo.zOffset))
    end
  end

  for i, smashableInfo in ipairs(mapData.smashables) do
    local level = world.levels[smashableInfo.level]
    if not level then
      logger.warn("Collectable of mapData.smashables["..tostring(i).."] had invalid level. Check spelling. Ignoring smashable.")
    else
      local x, y, tag, zOffset = smashableInfo.x, smashableInfo.y, smashableInfo.tag, smashableInfo.zOffset
      table.insert(world.smashables, smashable.new(x, y, level, tag, zOffset))
    end
  end

  for i, signpostInfo in ipairs(mapData.signposts) do
    local level = world.levels[signpostInfo.level]
    if not level then
      logger.warn("Signpost of mapData.signposts["..tostring(i).."] had invalid level. Check spelling. Ignoring signpost.")
    else
      local x, y, z = signpostInfo.x, signpostInfo.y, signpostInfo.z or 0
      local radius, rotation = signpostInfo.radius, signpostInfo.rz
      local content = signpostInfo.content or "[ EMPTY ]"
      table.insert(world.signposts, signpost.new(x, y, z, radius, rotation, content, level))
    end
  end

  for i, interactionInfo in ipairs(mapData.interactions) do
    local level = world.levels[interactionInfo.level]
    if not level then
      logger.warn("Interaction of mapData.interactions["..tostring(i).."] had invalid level. Check spelling. Ignoring interaction.")
    else
      local scriptID = interactionInfo.scriptID
      if not scriptID then
        logger.warn("Interaction of mapData.interactions["..tostring(i).."] had missing ScriptID. Ignoring interaction.")
      else
        local x, y, radius = interactionInfo.x, interactionInfo.y, interactionInfo.radius
        table.insert(world.interactions, interaction.new(level, x, y, radius, scriptID))
      end
    end
  end

  for scriptID, script in pairs(mapData.scripts) do
    scriptingEngine.registerScript(scriptID, script)
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

  nest.load()
end

world.unload = function()
  collectable.unload()
  smashable.unload()

  world.levels = { }
  world.transitions = { }
  world.props = { }
  world.specialProps = { }
  world.colliders = { }
  world.collectables = { }
  world.smashables = { }
  for _, signpost in ipairs(world.signposts) do
    signpost:unload() -- release assets
  end
  world.signposts = { }
  world.interactions = { }
  world.characters = { }
  world.debug = { }

  nest.unload()
end

world.setStage = function(toStage)
  local previousStage = world.stage
  world.stage = toStage
  if world.stage == "nest" then
    nest.enter()
    musicPlayer.pause()
  end
  if previousStage == "nest" then
    nest.leave()
    musicPlayer.continue()
  end
end

COLLECTABLE_SHADOW_MAX = 32
local sort_ClosestMag = function(a, b)
  return a.mag < b.mag
end

world.addTransition = function(x, y, width, height, edgeMap)
  for edgeName, levelName in pairs(edgeMap) do
    if world.levels[levelName] then
      edgeMap[edgeName] = world.levels[levelName]
    else
      logger.warn("Could not find level named '"..tostring(levelName).."'. Check spelling.")
    end
  end
  local t = transition.new(x, y, width, height, edgeMap)
  table.insert(world.transitions, t)
  local rect = { unpack(t.rect) }
  rect.color = { 1, 1, 0.75, 0.5 }
  table.insert(world.debug, rect)
end

world.update = function(dt, scale)
  scriptingEngine.update(dt) -- we want to process updates before we check for new interaction triggers

  if not player.isInputBlocked then
    local px, py, _ = player.getPosition()
    for _, interaction in ipairs(world.interactions) do
      if interaction:isInRange(px, py) and player.character:isInLevel(interaction.level) then
        if interaction:isTriggered() then
          scriptingEngine.startScript(interaction.scriptID)
        end
      end
    end
  end

  if world.stage == "world" then
    -- We update player after interactions, as scripts can lock player input, and thus stopping them move this frame
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
    for _, signpost in ipairs(world.signposts) do
      signpost:update(dt)
    end

    local playerCharacter = player.character
    if playerCharacter then
      if not player.isInputBlocked then
        for _, collectable in ipairs(world.collectables) do
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
              world.currencyLeaves = world.currencyLeaves + value
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

      local collectablePositions = { }
      for _, collectable in ipairs(world.collectables) do
        collectable:update(dt)
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

      local shader = g3d.shader
      local limit = math.min(#collectablePositions, COLLECTABLE_SHADOW_MAX)
      if limit > 0 then
        shader:send("collectablePositions", unpack(collectablePositions, 1, limit))
        shader:send("numCollectable", limit)
      else
        shader:send("numCollectable", 0)
      end
    end
  elseif world.stage == "nest" then
    nest.update(dt, scale)
  end
end

local lg = love.graphics
world.debugDraw = function()
  if world.stage == "world" then
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
    for _, smashable in ipairs(world.smashables) do
      smashable:debugDraw()
    end
    for _, signpost in ipairs(world.signposts) do
      signpost:debugDraw()
    end
    player.character:debugDraw()
    lg.pop()
  end
end

world.draw = function(scale)
  lg.setColor(1,1,1,1)

  if world.stage == "world" then
    for _, prop in ipairs(world.props) do
      prop:draw()
    end

    for _, collectable in ipairs(world.collectables) do
      collectable:draw()
    end

    for _, smashable in ipairs(world.smashables) do
      smashable:draw()
    end

    for _, character in pairs(world.characters) do
      character:draw() -- This includes the player character
    end

    -- Has transparency
    for _, signpost in ipairs(world.signposts) do
      signpost:draw()
    end
  elseif world.stage == "nest" then
    nest.draw()
    nest.drawUi(scale)
  end
  lg.push("all")
    lg.origin()
    lg.setColor(1,1,1,1)
    lg.print(("Collected Leaves: %2d\nUnspent Leaves: %d"):format(world.leaves, world.currencyLeaves), 20, 20)
  lg.pop()
end

world.mousemoved = function(...)
  if world.stage == "nest" then
    nest.mousemoved(...)
  end
end

return world