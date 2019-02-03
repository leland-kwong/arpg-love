local Component = require 'modules.component'
local collisionGroups = require 'modules.collision-groups'
local f = require 'utils.functional'
local tileData = require 'built.maps.home-base'
local iterateGrid = require 'utils.iterate-grid'
local msgBus = require 'components.msg-bus'
local groups = require 'components.groups'
local Font = require 'components.font'
local collisionWorlds = require 'components.collision-worlds'
local Portal = require 'components.portal'
local StarField = require 'components.star-field'
local loadImage = require 'modules.load-image'
local sceneManager = require 'scene.manager'

local inspect = require 'utils.inspect'
local defaultMapLayout = 'aureus'

local HomeBase = {
  id = 'HomeBase',
  group = groups.firstLayer,
  zoneTitle = 'Mothership',
  x = 0,
  y = 5,
  location = nil,
  drawOrder = function()
    return 1
  end
}

function HomeBase.init(self)
  local dynamic = require 'utils.dynamic-require'
  local questHandlers = dynamic 'components.quest-log.quest-handlers'
  questHandlers.start()

  Component.get('lightWorld'):setAmbientColor({1,1,1,1})

  local collisionObjectsLayer = f.find(tileData.layers, function(layer)
    return layer.name == 'collisions'
  end)

  local objectsLayer = f.find(tileData.layers, function(layer)
    return layer.name == 'objects'
  end)

  local universePortalPosition = f.find(objectsLayer.objects, function(obj)
    return obj.name == 'universePortalPosition'
  end)

  local playerPortalPosition = f.find(objectsLayer.objects, function(obj)
    return obj.name == 'playerPortalPosition'
  end)

  local initialPlayerPosition = f.find(objectsLayer.objects, function(obj)
    return obj.name == 'initialPlayerPosition'
  end)

  local Player = require 'components.player'
  local playerStartPosition = self.location and
    (
      (
        self.location.from == 'player' and
          playerPortalPosition or
          universePortalPosition
      ) or
      (
        self.location.from == 'universe' and
          universePortalPosition
      )
    ) or
    initialPlayerPosition
  self.player = Player.create({
    x = playerStartPosition.x,
    y = playerStartPosition.y,
    drawOrder = function(self)
      return self.group:drawOrder(self) + 1
    end
  }):setParent(self)

  local Dungeon = require 'modules.dungeon'

  local homeBaseMapId = Dungeon:new({
    layoutType = 'home-base'
  })

  Portal.create({
    style = 2,
    color = {1,1,1},
    x = universePortalPosition.x,
    y = universePortalPosition.y - 10,
    location = {
      tooltipText = 'Universe Portal',
      type = 'universe'
    }
  }):setParent(self)

  local shouldCreatePlayerPortal = Component.get('PlayerPortal') ~= nil
  if shouldCreatePlayerPortal then
    local globalState = require 'main.global-state'
    local mapId = globalState.mapLayoutsCache:get(self.location.layoutType)
    Portal.create({
      style = 1,
      x = playerPortalPosition.x,
      y = playerPortalPosition.y - 10,
      location = {
        tooltipText = 'Portal back to '..Dungeon:getData(mapId).options.layoutType,
        from = 'player',
        layoutType = self.location.layoutType
      }
    }):setParent(self)
  end

  Component.create({
    group = groups.all,
    x = self.x,
    y = self.y,
    draw = function()
      love.graphics.setColor(1,1,1)
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
  self.starField = StarField.create({
    direction = math.pi/2,
    emissionRate = 500,
    width = love.graphics.getWidth(),
    height = love.graphics.getHeight()
  }):setParent(self)

  self.listeners = {
    msgBus.on(msgBus.PORTAL_ENTER, function(location)
      if location.type == 'universe' then
        msgBus.send('MAP_TOGGLE')
        return
      end

      local Sound = require 'components.sound'
      Sound.playEffect('portal-enter.wav')

      if (location.layoutType) then
        local Dungeon = require 'modules.dungeon'
        msgBus.send(msgBus.SCENE_STACK_REPLACE, {
          scene = require 'scene.scene-main',
          props = {
            location = location
          }
        })
        return
      end
    end)
  }
end

function HomeBase.update(self)
  -- parallax effect for starfield
  local playerX, playerY = self.player:getPosition()
  self.starField:setPosition(
    playerX * -0.05,
    playerY * -0.05
  )
end

function HomeBase.draw(self)
  love.graphics.setColor(1,1,1)
  local shipBodyImage = loadImage('built/images/mothership/mothership.png')
  love.graphics.draw(
    shipBodyImage,
    self.x, self.y
  )
end

function HomeBase.drawOrder()
  return 2
end

function HomeBase.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(HomeBase)