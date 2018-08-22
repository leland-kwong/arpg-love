local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local AnimationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local gameWorld = require 'components.game-world'
local Gui = require 'components.gui.gui'
local camera = require 'components.camera'
local assign = require'utils.object-utils'.assign
local Color = require 'modules.color'

local animation = AnimationFactory:new({
  'treasure-chest'
}):update(0)

local w, h = animation:getSourceSize()

local TreasureChest = {
  group = groups.all,
  w = w,
  h = h
}

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {1,1,1,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = AnimationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
shader:send('outline_width', 1)

local function drawShadow(self)
  local r,g,b,a = love.graphics.getColor()
  love.graphics.setColor(0,0,0,0.15)
  love.graphics.draw(
    AnimationFactory.atlas,
    animation.sprite,
    self.x,
    self.y + self.h/2.5,
    0,
    1,
    1
  )
  -- set back to original color
  love.graphics.setColor(r,g,b,a)
end

function TreasureChest.init(self)
  local parent = self
  self:addCollisionObject('obstacle', self.x, self.y, self.w, self.h)
    :addToWorld(collisionWorlds.map)

  Gui.create({
    group = groups.all,
    x = self.x,
    y = self.y,
    w = self.w,
    h = self.h,
    getMousePosition = function()
      return camera:getMousePosition()
    end,
    onClick = function(self)
      consoleLog('open sesame!')

      local lootAlgorithm = require'components.loot-generator.algorithm-1'
      for i=1, 5 do
        local offsetX, offsetY = math.random(0, 10), math.random(0, 10)
        msgBus.send(msgBus.GENERATE_LOOT, {self.x + offsetX, self.y + offsetY, lootAlgorithm()})
      end
      parent:delete(true)
    end,
    onPointerEnter = function()
      msgBus.send(msgBus.ITEM_HOVERED, true)
    end,
    onPointerLeave = function()
      msgBus.send(msgBus.ITEM_HOVERED, false)
    end,
    draw = function(self)
      drawShadow(self)

      love.graphics.setShader(shader)
      shader:send('outline_color', self.hovered and outlineColor or Color.BLACK)

      love.graphics.draw(
        AnimationFactory.atlas,
        animation.sprite,
        self.x,
        self.y
      )

      love.graphics.setShader()
    end
  }):setParent(self)
end

return Component.createFactory(TreasureChest)