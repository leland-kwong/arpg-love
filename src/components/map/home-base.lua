local Component = require 'modules.component'
local Color = require 'modules.color'
local f = require 'utils.functional'
local tileData = require 'built.maps.home-base'
local iterateGrid = require 'utils.iterate-grid'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local config = require 'config.config'

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
  group = groups.all,
  x = 0,
  y = 5,
  drawOrder = function()
    return 1
  end
}

local function createStarField(self)
  local imageObj = loadImage('built/images/pixel-1x1-white.png')
  local psystem = love.graphics.newParticleSystem(imageObj, 500)
  self.psystem = psystem
  psystem:setParticleLifetime(3, 10) -- Particles live at least 2s and at most 5s.
  psystem:setEmissionRate(500)
  psystem:setDirection(math.pi / 2)
  psystem:setSpeed(5, 90)
  psystem:setSizes(1, 2, 3, 4)
  psystem:setEmissionArea(
    'ellipse',
    love.graphics.getWidth(config.gridSize),
    love.graphics.getHeight(config.gridSize),
    0,
    false
  )
  psystem:setSizeVariation(1)
	psystem:setLinearAcceleration(0, 0, 0, 0) -- Random movement in all directions.
  local col = Color.GOLDEN_PALE
  psystem:setColors(
    col[1], col[2], col[3], 0.1,
    col[1], col[2], col[3], 1,
    1, 1, 1, 0.75,
    1, 1, 1, 0
  )
end

function HomeBase.init(self)
  local collisionObjectsLayer = f.find(tileData.layers, function(layer)
    return layer.name == 'collisions'
  end)

  local objectsLayer = f.find(tileData.layers, function(layer)
    return layer.name == 'objects'
  end)

  local startPosition = f.find(objectsLayer.objects, function(obj)
    return obj.name == 'startPosition'
  end)

  local Player = require 'components.player'
  self.player = Player.create({
    x = startPosition.x,
    y = startPosition.y,
    drawOrder = function()
      return 12
    end
  }):setParent(self)

  Component.create({
    group = groups.all,
    x = self.x,
    y = self.y,
    draw = function()
      local shipRoomBorderImage = loadImage('built/images/mothership/mothership-room-border.png')
      love.graphics.draw(
        shipRoomBorderImage,
        self.x, self.y
      )
    end,
    drawOrder = function()
      return self.player:drawOrder() + 20
    end
  }):setParent(self)

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

  msgBus.send(msgBus.SET_BACKGROUND_COLOR, {0,0,0,0})
  createStarField(self)
end

function HomeBase.update(self, dt)
  self.psystem:update(dt)
end

function HomeBase.draw(self)
  love.graphics.setColor(1,1,1)
  local playerX, playerY = self.player:getPosition()
  -- parallax effect for starfield
  love.graphics.draw(
    self.psystem,
    playerX * -0.05,
    playerY * -0.05
  )
  local shipBodyImage = loadImage('built/images/mothership/mothership.png')
  love.graphics.draw(
    shipBodyImage,
    self.x, self.y
  )
end

return Component.createFactory(HomeBase)