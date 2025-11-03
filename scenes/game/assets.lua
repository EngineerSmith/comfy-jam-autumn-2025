local assets = { }


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
---

return assets