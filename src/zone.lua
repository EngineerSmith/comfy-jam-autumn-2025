local zone = {
  zones = { },
}

local lang = require("util.lang")

zone.addCollectable = function(zoneName, tag)
  if not zone.zones[zoneName] then
    zone.zones[zoneName] = {
      totals = { },
      collected = { },
    }
  end
  local z = zone.zones[zoneName]

  if not z.totals[tag] then
    z.totals[tag] = 0
  end
  z.totals[tag] = z.totals[tag] + 1
end

zone.setCollected = function(zoneName, tag)
  if not zone.zones[zoneName] then
    zone.zones[zoneName] = {
      totals = { },
      collected = { },
    }
  end
  local z = zone.zones[zoneName]

  if not z.collected[tag] then
    z.collected[tag] = 0
  end
  z.collected[tag] = z.collected[tag] + 1
end

zone.prettyPrint = function(zoneName)
  local prettyName = lang.getText("zone.name."..zoneName)
  local finalText = { prettyName }
  if not zone.zones[zoneName] then
    return finalText
  end
  local z = zone.zones[zoneName]

  for _, key in ipairs(zone.collectableOrder) do -- set via collectable.lua
    local total = z.totals[key]
    if total then
      local prettyName = lang.getText("collectable.name."..key)
      local collectedAmount = z.collected[key] or 0
      table.insert(finalText, ("%s: %d / %d"):format(prettyName, collectedAmount, total))
    end
  end

  return finalText
end

return zone