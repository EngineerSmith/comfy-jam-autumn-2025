local slick = require("libs.slick")

return {
  types = {
    CHARACTER = slick.newEnum({ type = "character" }),
    WALL = slick.newEnum({ type = "wall" }),
  },
}