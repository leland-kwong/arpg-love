local Component = require 'modules.component'
local f = require 'utils.functional'
local tileData = require 'built.maps.home-base'
local iterateGrid = require 'utils.iterate-grid'

local function parseTileSets(tileSets)
  local tileById = {}
  f.forEach(tileSets, function(set)
    local firstgid = set.firstgid
    f.forEach(set.tiles, function(tileDefinition)
      local actualId = tileDefinition.id + firstgid
      tileById[actualId] = tileDefinition
    end)
  end)
  return tileById
end

local inspect = require 'utils.inspect'

local HomeBase = {
  group = require 'components.groups'.all
}

function HomeBase.init(self)
  self.tileSet = parseTileSets(tileData.tilesets)

  local collisionObjectsLayer = f.find(tileData.layers, function(layer)
    return layer.name == 'collisions'
  end)

  local objectsLayer = f.find(tileData.layers, function(layer)
    return layer.name == 'objects'
  end)

  local startPosition = f.find(objectsLayer.objects, function(obj)
    return obj.name == 'startPosition'
  end)

  self.tiles = f.find(tileData.layers, function(layer)
    return layer.name == 'tiles'
  end)

  local Player = require 'components.player'
  Player.create({
    x = startPosition.x,
    y = startPosition.y
  })

  local collisionGroups = require 'modules.collision-groups'
  local collisionWorlds = require 'components.collision-worlds'
  f.forEach(collisionObjectsLayer.objects, function(c)
    self:addCollisionObject(
      collisionGroups.obstacle,
      c.x,
      c.y,
      c.width,
      c.height
    ):addToWorld(collisionWorlds.map)
  end)
end

local imagesCache = {}

local function loadImage(path)
  local img = imagesCache[path]
  if (not img) then
    img = love.graphics.newImage(path)
    img:setFilter('nearest')
    imagesCache[path] = img
  end
  return img
end

function HomeBase.draw(self)
  local imageObject = loadImage('built/images/mothership.png')
  love.graphics.draw(
    imageObject,
    0,5
  )
end

return Component.createFactory(HomeBase)