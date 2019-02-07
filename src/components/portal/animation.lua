local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'

local rect = AnimationFactory:newStaticSprite('gui-square-border')

local function zoomObject(o, dt)
  o.scale = o.scale + dt
  if o.scale >= 1.5 then
    o.scale = o.scale - 1.5
  end
end

local animationRenderers = {
  [1] = function(self, x, y)
    love.graphics.setColor(0,0,0,0.7)
    self.drawShape()

    love.graphics.setColor(self.color)
    rect:draw(x, y, self.rotation)

    love.graphics.setColor(1,1,1)
    love.graphics.stencil(self.stencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    love.graphics.setColor(self.color)
    local r1, r2, r3 = self.rect1, self.rect2, self.rect3
    rect:draw(x, y, -self.rotation*2, r1.scale, r1.scale)
    rect:draw(x, y, self.rotation*2, r2.scale, r2.scale)
    rect:draw(x, y, -self.rotation*2, r3.scale, r3.scale)
  end,

  [2] = function(self, x, y)
    love.graphics.setColor(0,0,0,0.7)
    self.drawShape()

    love.graphics.setColor(self.color)
    love.graphics.circle('line', x, y, self.w)

    love.graphics.setColor(1,1,1)
    love.graphics.stencil(self.stencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    love.graphics.setColor(self.color)
    local r1, r2, r3 = self.rect1, self.rect2, self.rect3
    love.graphics.circle('line', x, y, self.w * r1.scale)
    love.graphics.circle('line', x, y, self.w * r2.scale)
    love.graphics.circle('line', x, y, self.w * r3.scale)
  end
}

local stencilTypes = {
  [1] = function(self)
    love.graphics.push()
    local w,h = rect:getWidth(), rect:getHeight()
    love.graphics.translate(self.x, self.y - self.z)
    love.graphics.rotate(self.rotation)
    love.graphics.rectangle('fill', -w/2, -h/2, w, h)
    love.graphics.pop()
  end,

  [2] = function(self)
    love.graphics.push()
    love.graphics.translate(self.x, self.y - self.z)
    love.graphics.rotate(self.rotation)
    love.graphics.circle('fill', 0, 0, self.w)
    love.graphics.pop()
  end
}

return Component.createFactory({
  x = 0,
  y = 0,
  w = 22,
  h = 22,
  group = 'all',
  color = {1,0.9,0},
  style = 1,
  scale = 1,
  init = function(self)
    self.rect1 = {
      scale = 0,
    }

    self.rect2 = {
      scale = 0.5
    }

    self.rect3 = {
      scale = 1
    }

    self.rotation = 0

    self.drawShape = function()
      return stencilTypes[self.style](self)
    end
    self.stencil = self.drawShape
  end,
  update = function(self, dt)
    zoomObject(self.rect1, dt*1.15)
    zoomObject(self.rect2, dt*1.15)
    zoomObject(self.rect3, dt*1.15)

    self.rotation = self.rotation + dt
  end,
  draw = function(self)
    local x, y = self.x, self.y - self.z

    local lightWorld = Component.get('lightWorld')
    if lightWorld then
      lightWorld:addLight(x, y, 20, self.color)
    end

    love.graphics.push()
    love.graphics.scale(self.scale)
    local scaleDiff = (1 - self.scale)/self.scale
    love.graphics.translate(x * scaleDiff, y * scaleDiff)
    animationRenderers[self.style](self, x, y)
    love.graphics.setStencilTest()
    love.graphics.pop()
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self)
  end
})