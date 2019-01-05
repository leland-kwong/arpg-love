local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'
local Gui = require 'components.gui.gui'
local msgBus = require 'components.msg-bus'
local Color = require 'modules.color'
local itemConfig = require(require('alias').path.items..'.config')
require 'components.interactable-indicators'

local bodyGraphic = AnimationFactory:newStaticSprite('treasure-chest-body')
local lidGraphic = AnimationFactory:newStaticSprite('treasure-chest-lid')
local bodyWidth = math.max(
  bodyGraphic:getWidth(),
  lidGraphic:getWidth()
)

local speed = 2
local acceleration = 5
local emissionAreaWidth = bodyWidth/1.4
local particleScaleY = 6
local animation = AnimationFactory:newStaticSprite('pixel-white-1x1')
local psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 200)
local col = {1,1,0.5}
psystem:setColors(
  col[1], col[2], col[3], 0,
  col[1], col[2], col[3], 1,
  col[1], col[2], col[3], 0
)
-- psystem:setEmissionRate(10)
psystem:setQuads(animation.sprite)
psystem:setOffset(animation:getOffset())
psystem:setDirection(-math.pi / 2)
psystem:setSpeed(speed)
psystem:setLinearAcceleration(
  0,
  0,
  0,
  -acceleration
) -- move particles in all random directions
psystem:setSizes(1, 1, 1, 1)
psystem:setSizeVariation(1)
psystem:setEmissionArea('ellipse', emissionAreaWidth, 2, 0, false)
Component.create({
  id = 'TreasureChestParticleSystem',
  init = function(self)
    Component.addToGroup(self, 'all')
  end,
  update = function(self, dt)
    psystem:update(dt)
  end,
  draw = function()
    love.graphics.setColor(1,1,1)
    love.graphics.draw(psystem, 0, 0, 0, 1, particleScaleY, 0, 10/particleScaleY)
  end,
  drawOrder = function(self)
    return 5
  end
})

local handleTreasureOpen = function(self, parent)
  if parent.opened then
    return
  end

  if parent.canOpen == true then
    parent.opened = true
    local tween = require 'modules.tween'
    parent.tween = tween.new(1, parent, {lidOffsetY = -300, lidOpacity = 0}, tween.easing.inExpo)

    local Sound = require 'components.sound'
    Sound.playEffect('treasure-open.wav')

    local lootData = parent.lootData()
    local uid = require 'utils.uid'
    Component.addToGroup(uid(), 'loot', {
      delay = parent.delay or 0.25,
      x = self.x,
      y = self.y,
      itemData = lootData.itemData,
      guaranteedItems = lootData.guaranteedItems
    })
  end
end

return Component.createFactory({
  lootData = function()
    return {
      guaranteedItems = {},
      itemData = {
        level = 1,
        dropRate = 0,
        minRarity = itemConfig.rarity.NORMAL,
        maxRarity = itemConfig.rarity.NORMAL,
      },
    }
  end,
  -- debug = true,
  lidOffsetY = 0,
  lidOpacity = 1,
  init = function(self)
    local parent = self
    Component.addToGroup(self, 'all')
    Component.addToGroup(self, 'gameWorld')
    Component.addToGroup(self, 'autoVisibility')

    self.height = 27

    self.interactNode = Gui.create({
      group = 'all',
      inputContext = 'treasureChest',
      x = parent.x - bodyWidth/2,
      y = parent.y - 15,
      width = bodyWidth,
      height = parent.height,
      opened = false,
      getMousePosition = function(self)
        local camera = require 'components.camera'
        return camera:getMousePosition()
      end,
      onClick = function(self)
        handleTreasureOpen(self, parent)
      end
    }):setParent(self)

    local collisionWorlds = require 'components.collision-worlds'
    local collisionYAdjustment = 6
    self:addCollisionObject('obstacle', self.interactNode.x, self.interactNode.y + collisionYAdjustment, self.interactNode.width, self.interactNode.height - collisionYAdjustment)
      :addToWorld(collisionWorlds.map)

    self.particleClock = 0
  end,
  update = function(self, dt)
    self:setDrawDisabled(not self.isInViewOfPlayer)
    if (not self.isInViewOfPlayer) then
      return
    end

    self.canOpen = (not self.opened) and
      msgBus.send('INTERACT_ENVIRONMENT_OBJECT', self)

    if self.tween then
      local complete = self.tween:update(dt)
    end

    self.particleClock = self.particleClock + dt
    if self.particleClock > 0.1 then
      self.particleClock = 0
      psystem:setParticleLifetime(0.9)
      psystem:setPosition(self.x, self.y / particleScaleY)
      psystem:emit(1)
    end
  end,
  draw = function(self)
    local lightWorldRef = Component.get('lightWorld')
    if lightWorldRef then
      lightWorldRef:addLight(self.x, self.y, 15, Color.SKY_BLUE)
    end

    love.graphics.setColor(0,0,0,0.4)
    bodyGraphic:draw(self.x, self.y + 4, nil, nil, -1)

    love.graphics.setColor(1,1,1)

    if self.canOpen then
      Component.addToGroup(self:getId(), 'interactableIndicators', {
        x = self.interactNode.x,
        y = self.y
      })
    end

    local Shaders = require 'modules.shaders'
    local shader = Shaders('pixel-outline.fsh')

    if (not self.opened) then
      if self.interactNode.hovered then
        local atlasData = AnimationFactory.atlasData
        love.graphics.setShader(shader)
        shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
        shader:send('outline_width', 1)
        shader:send('outline_color', Color.WHITE)
      end
    end

    bodyGraphic:draw(self.x, self.y)

    if self.lidOpacity > 0 then
      love.graphics.setColor(1,1,1,self.lidOpacity)
      lidGraphic:draw(self.x, self.y + self.lidOffsetY)
    end

    shader:send('outline_width', 0)
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self)
  end
})