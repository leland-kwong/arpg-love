local AnimationFactory = LiveReload 'components.animation-factory'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local camera = require 'components.camera'
local FrostOrb = LiveReload 'components.abilities.frost-orb'

local getMousePosition = function()
  local mx, my = love.mouse.getPosition()
  return mx/camera.scale, my/camera.scale
end

return Component.createFactory({
  -- id = 'CloudEffect',
  group = 'all',
  init = function(self)
    self.objects = {}
    local animation = AnimationFactory:newStaticSprite('cloud')
    self.psystem = love.graphics.newParticleSystem(AnimationFactory.atlas, 5000)
    self.psystem:setQuads(animation.sprite)
    self.psystem:setOffset(animation:getOffset())
    self.psystem:setColors(
      1,1,1,1,
      1,1,1,1,
      1,1,1,0
    )
    self.psystem:setDirection(math.pi/2)
    self.psystem:setSizes(1.4, 0.3)
    self.psystem:setSpeed(10, 10)
    -- self.psystem:setRotation(math.pi/4)
    -- self.psystem:setLinearAcceleration(0, 0, 0, 300)
    self.psystem:setParticleLifetime(0.4)
    self.psystem:setEmissionRate(10)
    self.psystem:setEmissionArea('ellipse', 3, 3)

    -- self.listeners = {
    --   msgBus.on('MOUSE_CLICKED', function(ev)
    --     local mx, my = camera:getMousePosition()
    --     local x2, y2 = math.random(50, 100), math.random(0, 100)
    --     local orb = FrostOrb.create({
    --       x = mx,
    --       y = my,
    --       x2 = x2,
    --       y2 = y2
    --     })
    --     table.insert(self.objects, orb)
    --   end)
    -- }
  end,
  update = function(self, dt)
    if self.parent.speed == 0 then
      self.psystem:setEmissionRate(0)
    end
    self.psystem:setPosition(self.x, self.y)
    -- for _,o in pairs(Component.groups.cloudEffect.getAll()) do
    --   if (o.speed > 0) then
    --     o.__emitClock = (o.__emitClock or 0) + dt
    --     if o.__emitClock >= 0.07 then
    --       o.__emitClock = 0

    --       -- -- print(o.dx, o.dy)

    --       self.psystem:emit(1)
    --     end
    --   end
    -- end
    self.psystem:update(dt)
    -- self.psystem:setEmissionRate(0)
  end,
  draw = function(self)
    local Color = require 'modules.color'
    love.graphics.setColor(Color.rgba255(188, 231, 255))
    love.graphics.draw(self.psystem)
  end,
  drawOrder = function(self)
    return Component.groups.all:drawOrder(self.parent)
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})