local Component = require 'modules.component'
local config = require 'config.config'
local AnimationFactory = require 'components.animation-factory'
local animation = AnimationFactory:newStaticSprite('environment-entrance')
local width, height = animation:getWidth(), animation:getHeight()
local Position = require 'utils.position'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local minimapColor = Color.CYAN

local function collisionFilter(_, other)
  local collisionGroups = require 'modules.collision-groups'
  if collisionGroups.matches(other.group, 'player') then
    return 'cross'
  end
  return false
end

return Component.createFactory({
  locationName = '',
  class = 'environment',
  onEnter = function()
    print('exit entered')
  end,
  init = function(self)
    Component.addToGroup(self:getId(), 'all', self)
    self:setParent(Component.get('MAIN_SCENE'))

    local collisionWorlds = require 'components.collision-worlds'
    local ox, oy = animation:getSourceOffset()
    self.collision = self:addCollisionObject(
      'obstacle',
      self.x,
      self.y,
      width,
      config.gridSize,
      ox,
      0
    ):addToWorld(collisionWorlds.map)
    self.mapPointerPosition = {
      x = self.x + width/2 - 8,
      y = self.y + height/2
    }

    self.gridX, self.gridY = Position.pixelsToGridUnits(self.x, self.y, config.gridSize)
  end,
  update = function(self)
    local minimapRef = Component.get('miniMap')
    self.minimapRenderer = self.minimapRenderer or function()
      love.graphics.setColor(minimapColor)
      love.graphics.rectangle('fill', 0, 0, 2, 1)
      -- entrance direction
      love.graphics.circle('fill', 1, 3, 2)
    end
    minimapRef:renderBlock(self.gridX, self.gridY, self.minimapRenderer)

    local calcDist = require 'utils.math'.dist
    local distFromPlayer = calcDist(
      self.mapPointerPosition.x,
      self.mapPointerPosition.y,
      Component.get('PLAYER').x,
      Component.get('PLAYER').y
    )

    if distFromPlayer <= (60 * config.gridSize) then
      Component.get('hudPointerWorld')
        :add(
          Component.get('PLAYER'),
          self.mapPointerPosition,
          minimapColor
        )
    end

    local len = select(4, self.collision:check(self.x, self.y + 4, collisionFilter))
    local playerCollided = len > 0
    if playerCollided then
      self:onEnter()
    end
  end,
  draw = function(self)
    local ox, oy = animation:getOffset()
    Component.get('lightWorld')
      :addLight(self.x + width/2, self.y, width / 2)
    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      animation.sprite,
      self.x,
      self.y,
      0,
      1,
      1,
      ox,
      oy
    )

    if self.debug then
      love.graphics.setColor(1,1,1,0.5)
      love.graphics.rectangle(
        'fill',
        self.collision.x - self.collision.ox,
        self.collision.y - self.collision.oy,
        self.collision.w,
        self.collision.h
      )
    end

    require 'components.map-text'
    local Color = require 'modules.color'
    local camera = require 'components.camera'
    local GuiText = require 'components.gui.gui-text'
    local MapText = Component.get('MapText')
    local text = self.locationName
    local textWidth = GuiText.getTextSize(text, MapText.font)
    MapText:add(
      text,
      Color.WHITE,
      self.x + animation:getWidth()/2 - textWidth/2,
      self.y - oy - 9
    )
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self) + 5
  end,
  serialize = function(self)
    return self.initialProps
  end
})