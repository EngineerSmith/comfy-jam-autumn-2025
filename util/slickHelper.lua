local slick = require("libs.slick")

local slickHelper = { }

-- todo add sound variable, and play if character walks into such type
-- Tags could define interaction too
-- Thus to correctly compare tag.type == tag.type

slickHelper.tags = {
  CHARACTER         = slick.newEnum({ type = "character"      }),
  WALL              = slick.newEnum({ type = "wall"             , audio = "audio.fx.softImpact" }),
  ROCK              = slick.newEnum({ type = "rock"             , audio = "audio.fx.hit.rock"   }),
  LOG               = slick.newEnum({ type = "log"              , audio = "audio.fx.hit.log"    }),
  POT               = slick.newEnum({ type = "pot"              , audio = "audio.fx.hit.pot"    }),
  PLANT             = slick.newEnum({ type = "plant"            , audio = "audio.fx.hit.plant"  }),
  SMASHABLE_POT     = slick.newEnum({ type = "smashable_pot"    , audio = "audio.fx.hit.pot"      , isSmashable = true }),
  SMASHABLE_PUMPKIN = slick.newEnum({ type = "smashable_pumpkin", audio = "audio.fx.softImpact"   , isSmashable = true }),
}

slickHelper.typeArrayToTags = function(array)
  if #array == 0 then
    return nil
  end
  local results = { }
  for _, tagType in ipairs(array) do
    if type(tagType) == "string" then
      local tag = slickHelper.tags[tagType:upper()]
      if tag then
        table.insert(results, tag.value)
      end
    end
  end
  return results
end

slickHelper.getTagAssetList = function()
  local assets = { }
  for _, tag in pairs(slickHelper.tags) do
    if tag.value.audio then
      table.insert(assets, tag.value.audio)
    end
  end
  return assets
end

slickHelper.rotateShapeVertices = function(shapeDefinition, radians, centerX, centerY)
  centerX = centerX or 0
  centerY = centerY or 0

  local cosTheta = math.cos(radians)
  local sinTheta = math.sin(radians)
  local vertices = shapeDefinition.arguments

  for i = 1, #vertices, 2 do
    local x = vertices[i]
    local y = vertices[i + 1]

    local translatedX = x - centerX
    local translatedY = y - centerY

    local rotatedX = translatedX * cosTheta - translatedY * sinTheta
    local rotatedY = translatedX * sinTheta + translatedY * cosTheta
    
    vertices[i] = rotatedX + centerX
    vertices[i + 1] = rotatedY + centerY
  end
  
  return shapeDefinition
end

return slickHelper