local assets = {
-- 3D models
  "model.nest.interior",
  "model.nest.interior.lightShaft",
  "model.nest.interior.bed.0",
  "model.nest.interior.bed.1",
  "model.nest.interior.bed.2",
  "model.nest.interior.bed.3",
  "model.nest.interior.bed.4",
-- Sprites
  "sprite.hedgehog.idle.loop",
  "sprite.hedgehog.walking.loop",
  "sprite.hedgehog.sleep.start",
  "sprite.hedgehog.sleep.loop",
  "sprite.hedgehog.sleep.exit",
  "sprite.hedgehog.alert.start",
  "sprite.hedgehog.alert.loop",
  "sprite.hedgehog.alert.exit",
  "sprite.ball.idle.loop",
  "sprite.ball.walking.loop",
-- Audio
  "audio.fx.softImpact",
}

--- Grab the models needed for mapData
local lookup = { }
for _, asset in ipairs(assets) do
  lookup[asset] = true
end

local mapData = require("assets.level.mapData")
for _, modelInfo in ipairs(mapData.models) do
  if not lookup[modelInfo.model] then
    table.insert(assets, modelInfo.model)
    lookup[modelInfo.model] = true
  end
  if modelInfo.texture and not lookup[modelInfo.texture] then
    table.insert(assets, modelInfo.texture)
    lookup[modelInfo.texture] = true
  end
end

  -- Collectables
local assetList = require("src.collectable").getAssetList()
for _, assetKey in ipairs(assetList) do
  if not lookup[assetKey] then
    table.insert(assets, assetKey)
    lookup[assetKey] = true
  end
end
--- Music Player
local assetList = require("src.musicPlayer").music
for _, assetKey in ipairs(assetList) do
  if not lookup[assetKey] then
    table.insert(assets, assetKey)
    lookup[assetKey] = true
  end
end
---
if lookup["model.flower.red3"] then
  print("Found red3")
end

if lookup["model.flower.yellow3"] then
  print("Found yellow3")
end

return assets