local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local AnimationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local gameWorld = require 'components.game-world'
local Gui = require 'components.gui.gui'
local camera = require 'components.camera'
local extend = require'utils.object-utils'.extend
local Color = require 'modules.color'

local animation = AnimationFactory:new({
  'treasure-chest'
}):update(0)

local pixelOutlineShader = love.filesystem.read('modules/shaders/pixel-outline.fsh')
local outlineColor = {1,1,1,1}
local shader = love.graphics.newShader(pixelOutlineShader)
local atlasData = AnimationFactory.atlasData
shader:send('sprite_size', {atlasData.meta.size.w, atlasData.meta.size.h})
shader:send('outline_width', 1)

local w, h = animation:getSourceSize()

local function drawShadow(self)
  local r,g,b,a = love.graphics.getColor()
  love.graphics.setColor(0,0,0,0.3)
  love.graphics.draw(
    AnimationFactory.atlas,
    animation.sprite,
    self.x,
    self.y + 2 + (self.h * 1.3),
    0,
    1,
    -1
  )
  -- set back to original color
  love.graphics.setColor(r,g,b,a)
end

local function getRandomDirection()
  return math.random(0, 1) == 1 and 1 or -1
end

local TreasureChest = extend(Gui, {
  group = groups.all,
  w = w,
  h = h,
  onCreate = function(self)
    self:addCollisionObject('obstacle', self.x, self.y, self.w, self.h - 6, 0, -6)
      :addToWorld(collisionWorlds.map)
  end,
  getMousePosition = function()
    return camera:getMousePosition()
  end,
  onClick = function(self)
    local lootAlgorithm = require'components.loot-generator.algorithm-1'
    for i=1, 5 do
      local offsetX, offsetY = math.random(0, 10) * getRandomDirection(),
        math.random(0, 10) * getRandomDirection()
      msgBus.send(msgBus.GENERATE_LOOT, {self.x + offsetX, self.y + offsetY, lootAlgorithm()})
    end
    self:delete(true)
  end,
  onPointerEnter = function()
    msgBus.send(msgBus.ITEM_HOVERED, true)
  end,
  onPointerLeave = function()
    msgBus.send(msgBus.ITEM_HOVERED, false)
  end,
  draw = function(self)
    drawShadow(self)

    if self.hovered then
      love.graphics.setShader(shader)
      shader:send('outline_color', self.hovered and outlineColor or Color.BLACK)
    end

    love.graphics.setColor(1,1,1)
    love.graphics.draw(
      AnimationFactory.atlas,
      animation.sprite,
      self.x,
      self.y
    )

    if self.hovered then
      love.graphics.setShader()
    end
  end,
  drawOrder = function(self)
    return self.group:drawOrder(self) + 2
  end
})

return Component.createFactory(TreasureChest)