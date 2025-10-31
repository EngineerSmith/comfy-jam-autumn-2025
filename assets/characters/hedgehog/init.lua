local character = require("src.character")

return function()
  local hedgehog = character.create("hedgehog", 20, 5)
  hedgehog.color = { 1, 0, 0, 1 } -- debug

  return hedgehog
end
