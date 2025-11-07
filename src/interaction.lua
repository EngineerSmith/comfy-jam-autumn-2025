local interaction = { }
interaction.__index = interaction

local input = require("util.input")

interaction.new = function(level, x, y, radius, scriptID, key)
  local self = setmetatable({
    level = level,
    x = x, y = y,
    radius = radius or 2,
    scriptID = scriptID or "UNKNOWN", -- play "fault" script
    key = key or "interact",
  }, interaction)
  self.radiusSqu = self.radius * self.radius
  return self
end

interaction.isInRange = function(self, x, y)
  local dx, dy = self.x - x, self.y - y
  local magSqu = dx * dx + dy * dy
  return magSqu <= self.radiusSqu
end

interaction.isTriggered = function(self)
  return input.baton:pressed(self.key)
end

return interaction