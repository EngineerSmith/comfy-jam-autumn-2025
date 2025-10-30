local character = require("src.character")

return function()
  local hedgehog = character.create(0, 0, 4, 2)
  hedgehog.color = { 1, 0, 0, 1 } -- debug

  return hedgehog
end
