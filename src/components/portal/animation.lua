local Component = require 'modules.component'
local AnimationFactory = require 'components.animation-factory'

local rect = AnimationFactory:newStaticSprite('gui-square-border')

local function zoomObject(o, dt)
  o.scale = o.scale + dt
  if o.scale >= 1.5 then
    o.scale = o.scale - 1.5
  end
end

return Component.createFactory({
  id = 'PortalExample',
  x = 250,
  y = 100,
  w = 1,
  h = 1,
  group = 'all',
  color = {1,0,1},
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

    self.drawRectangle = function()
      love.graphics.push()
      local w,h = rect:getWidth(), rect:getHeight()
      love.graphics.translate(self.x, self.y)
      love.graphics.rotate(self.rotation)
      love.graphics.rectangle('fill', -w/2, -h/2, w, h)
      love.graphics.pop()
    end
    self.stencil = self.drawRectangle
  end,
  update = function(self, dt)
    zoomObject(self.rect1, dt*1.15)
    zoomObject(self.rect2, dt*1.15)
    zoomObject(self.rect3, dt*1.15)

    self.rotation = self.rotation + dt
  end,
  draw = function(self)
    local lightWorld = Component.get('lightWorld')
    if lightWorld then
      lightWorld:addLight(self.x, self.y, 20, self.color)
    end
    love.graphics.setColor(0,0,0)
    self.drawRectangle()

    love.graphics.setColor(self.color)
    rect:draw(self.x, self.y, self.rotation, self.w, self.h)

    love.graphics.setColor(1,1,1)
    love.graphics.stencil(self.stencil, 'replace', 1)
    love.graphics.setStencilTest('greater', 0)

    love.graphics.setColor(self.color)
    local r1, r2, r3 = self.rect1, self.rect2, self.rect3
    rect:draw(self.x, self.y, -self.rotation*2, self.w * r1.scale, self.h * r1.scale)
    rect:draw(self.x, self.y, self.rotation*2, self.w * r2.scale, self.h * r2.scale)
    rect:draw(self.x, self.y, -self.rotation*2, self.w * r3.scale, self.h * r3.scale)

    love.graphics.setStencilTest()
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self) + 1
  end
})