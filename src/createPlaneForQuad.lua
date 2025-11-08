local lfs = love.filesystem

local g3d = require("libs.g3d")

local PIXEL_TO_UNIT_SCALE = 32 -- 32x32 = 1:1

return function(uNorm, vNorm, wNorm, hNorm, texture, scale, plane)
  plane = plane or "XY"

  local textureWidth, textureHeight = texture:getDimensions()

  local pixelScale = PIXEL_TO_UNIT_SCALE / scale

  local framePixelW = textureWidth  * wNorm
  local framePixelH = textureHeight * hNorm

  local h = framePixelH / pixelScale
  local aspect = framePixelW / framePixelH
  local w = h * aspect

  local halfW = w / 2
  local halfH = h / 2

  local uStart = uNorm         -- Left U
  local vStart = vNorm         -- Top V
  local uEnd   = uNorm + wNorm -- right U
  local vEnd   = vNorm + hNorm -- Bottom V

  local R, G, B, A = 1.0, 1.0, 1.0, 1.0

  local verts
  if plane == "XY" then
    local nvX, nvY, nvZ = 0, 0, 1

    local yMin = -halfH
    local yMax = halfH

    -- Vertex Format: x, y, z, u, v, r, g, b, a, nx, ny, nz
    verts = {
      {  halfW, yMin, 0,   uEnd,   vEnd, R, G, B, A, nvX, nvY, nvZ },
      {  halfW, yMax, 0,   uEnd, vStart, R, G, B, A, nvX, nvY, nvZ },
      { -halfW, yMax, 0, uStart, vStart, R, G, B, A, nvX, nvY, nvZ },
      
      { -halfW, yMax, 0, uStart, vStart, R, G, B, A, nvX, nvY, nvZ },
      { -halfW, yMin, 0, uStart,   vEnd, R, G, B, A, nvX, nvY, nvZ },
      {  halfW, yMin, 0,   uEnd,   vEnd, R, G, B, A, nvX, nvY, nvZ },
    }
  elseif plane == "XZ" then
    local nvX, nvY, nvZ = 0, 1, 0

    local zMin = 0
    local zMax = h

    -- Vertex Format: x, y, z, u, v, r, g, b, a, nx, ny, nz
    verts = {
      {  halfW, 0, zMin,   uEnd,   vEnd, R, G, B, A, nvX, nvY, nvZ },
      {  halfW, 0, zMax,   uEnd, vStart, R, G, B, A, nvX, nvY, nvZ },
      { -halfW, 0, zMax, uStart, vStart, R, G, B, A, nvX, nvY, nvZ },
      
      { -halfW, 0, zMax, uStart, vStart, R, G, B, A, nvX, nvY, nvZ },
      { -halfW, 0, zMin, uStart,   vEnd, R, G, B, A, nvX, nvY, nvZ },
      {  halfW, 0, zMin,   uEnd,   vEnd, R, G, B, A, nvX, nvY, nvZ },
    }
  end

  return g3d.newModel(verts, nil, texture) -- 2nd arg is now a MTL file path
end