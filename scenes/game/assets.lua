local assets = {
  "audio.music.fall",
  "audio.music.roundabout",
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

return assets