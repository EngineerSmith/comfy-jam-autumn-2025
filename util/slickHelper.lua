local slick = require("libs.slick")

local slickHelper = { }

-- todo add sound variable, and play if character walks into such type
-- Tags could define interaction too
-- Thus to correctly compare tag.type == tag.type

slickHelper.tags = {
  CHARACTER = slick.newEnum({ type = "character" }),
  WALL      = slick.newEnum({ type = "wall" }),
  LOG       = slick.newEnum({ type = "log" }),
}

return slickHelper