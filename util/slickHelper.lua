local slick = require("libs.slick")

local slickHelper = { }

slickHelper.types = {
  CHARACTER = slick.newEnum({ type = "character" }),
  WALL = slick.newEnum({ type = "wall" }),
}

return slickHelper