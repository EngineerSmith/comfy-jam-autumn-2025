local wind = {
  objects = { },
  spawnTimer = 0,
  spawnInterval = 0.15, -- Spawn a new leaf every 0.3 seconds
}
wind.__index = wind

local g3d = require("libs.g3d")
local flux = require("libs.flux")
local slick = require("libs.slick")
local slickHelper = require("util.slickHelper")

local logger = require("util.logger")
local audioManager = require("util.audioManager")
local assetManager = require("util.assetManager")


local leafTypes = {
  { color = { 0.57, 0.32, 0.22 }, },
  { color = { 0.62, 0.28, 0.23 }, },
  { color = { 0.59, 0.21, 0.17 }, },
  { color = { 0.89, 0.77, 0.29 }, },
  { color = { 0.75, 0.65, 0.15 }, },
  { color = { 0.35, 0.55, 0.25 }, },
}

local CUBE = g3d.newModel("scenes/game/cube.obj")
local lg = love.graphics

local spawnLeaf = function(x, y, z)
  local litter = {
    x = x, y = y, z = z,
    rx = 0, ry = 0, rz = 0,
    opacity = 0.0,
    scale = love.math.random(10, 25) / 100, -- 0.10..0.25
    color = leafTypes[love.math.random(#leafTypes)].color,
  }
  table.insert(wind.objects, litter)

  local fadeInDuration = 0.5 + love.math.random() * 0.5
  local driftDuration = 2.0 + love.math.random() * 2.0
  local fadeOutDuration = 0.5 + love.math.random() * 0.5

  local angle = math.rad(love.math.random(-15, 15))
  local dist = 10 + love.math.random() * 6
  local zBobRange = love.math.random() * 0.5

  local distB = dist * 0.15
  local midX = x + math.cos(angle) * distB
  local midY = y + math.sin(angle) * distB
  local midZ = z + zBobRange * 0.5

  local distC = dist * 0.85
  local finalX = x + math.cos(angle) * distC
  local finalY = y + math.sin(angle) * distC
  local finalZ = z - zBobRange

  local cleanupX = x + math.cos(angle) * dist
  local cleanupY = y + math.sin(angle) * dist
  local cleanupZ = z - zBobRange

  flux.to(litter, fadeInDuration, {
      opacity = 0.7 + love.math.random() * 0.3,
      x = midX,
      y = midY,
      z = midZ,
    })
    :ease("quadout")
    :after(driftDuration, {
      x = finalX,
      y = finalY,
      z = finalZ,
      rx = love.math.random() * 8 * math.pi,
      ry = love.math.random() * 8 * math.pi,
      rz = love.math.random() * 8 * math.pi,
    })
    :ease("sineinout")
    :after(fadeOutDuration, {
      opacity = 0.0,
      x = cleanupX,
      y = cleanupY,
      z = cleanupZ,
    })
    :ease("quadin")
    :oncomplete(function()
      for i, l in ipairs(wind.objects) do
        if l == litter then
          table.remove(wind.objects, i)
          break
        end
      end
    end)
end

wind.load = function(playerX, playerY, playerZ, cameraRadius)
  wind.objects = { }
  for i = 1, 25 do
    local spawnX = playerX + love.math.random(-cameraRadius, cameraRadius)
    local spawnY = playerY + love.math.random(-cameraRadius, cameraRadius)
    local spawnZ = playerZ + love.math.random(20, 80) / 10
    spawnLeaf(spawnX, spawnY, spawnZ)
  end
end

wind.update = function(dt, playerX, playerY, playerZ, cameraRadius)
  wind.spawnTimer = wind.spawnTimer + dt
  while wind.spawnTimer >= wind.spawnInterval do
    wind.spawnTimer = wind.spawnTimer - wind.spawnInterval
    local spawnAngle = love.math.random() * 2 * math.pi
    local spawnDist = love.math.random() * cameraRadius
    local spawnX = playerX + math.cos(spawnAngle) * spawnDist
    local spawnY = playerY + math.sin(spawnAngle) * spawnDist
    local spawnZ = playerZ + love.math.random(20, 80) / 10
    spawnLeaf(spawnX, spawnY, spawnZ)
  end
end

wind.draw = function()
  lg.push("all")
  for _, litter in ipairs(wind.objects) do
    local r, g, b = unpack(litter.color)
    lg.setColor(r, g, b, litter.opacity)
    CUBE:setTranslation(litter.x, litter.y, litter.z)
    CUBE:setRotation(litter.rx, litter.ry, litter.rz)
    CUBE:setScale(litter.scale)
    CUBE:draw()
  end
  lg.pop()
end

return wind