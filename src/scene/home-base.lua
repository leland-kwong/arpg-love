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
local imageObj = loadImage('built/images/pixel-1x1-white.png')

local inspect = require 'utils.inspect'

local HomeBase = {
  group = groups.all,
  zoneTitle = 'Mothership',
  x = 0,
  y = 5,
  drawOrder = function()
    return 1
  end
}

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
    drawOrder = function(self)
      return self.group:drawOrder(self) + 1
    end
  }):setParent(self)

  Portal.create({
    x = startPosition.x,
    y = startPosition.y,
    locationName = 'Aureus'
  }):setParent(self)

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
    msgBus.on(msgBus.PORTAL_ENTER, function()
      local msgBusMainMenu = require 'components.msg-bus-main-menu'
      local sceneManager = require 'scene.manager'
      if (not sceneManager:canPop()) then
        msgBus.send(msgBus.SCENE_STACK_REPLACE, {
          scene = require 'scene.scene-main'
        })
        return
      end

      msgBus.send(
        msgBus.SCENE_STACK_POP
      )
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

function HomeBase.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(HomeBase)