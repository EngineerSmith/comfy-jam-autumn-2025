local assets = {
-- Sprites
  "sprite.leaves.1",
  "sprite.trees.1",
  "sprite.trees.2",
  "sprite.hedgehog.sleep.loop",
-- textures
  "ui.logoES",
  "ui.3slice.basic",
  "ui.title",
  "ui.subtitle",
-- audios
  "audio.ui.select",
  "audio.ui.click",
}
local lookup = { }
for _, asset in ipairs(assets) do
  lookup[asset] = true
end

--- Music Player
local assetList = require("src.musicPlayer").music
for _, assetKey in ipairs(assetList) do
  if not lookup[assetKey] then
    table.insert(assets, assetKey)
    lookup[assetKey] = true
  end
end

return assets