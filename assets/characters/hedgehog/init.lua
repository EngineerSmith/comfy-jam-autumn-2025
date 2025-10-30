local character = require("src.character")

return function()
  local hedgehog = character.create("hedgehog", 0, 0, 20, 2)
  hedgehog.color = { 1, 0, 0, 1 } -- debug

  return hedgehog
end
