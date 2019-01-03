local dynamicRequire = require 'utils.dynamic-require'
local Component = require 'modules.component'
local AnimationFactory = dynamicRequire 'components.animation-factory'
local Gui = require 'components.gui.gui'

local TreasureChest = Component.createFactory({
  lidOffsetY = 0,
  init = function(self)
    local parent = self
    Component.addToGroup(self, 'all')

    self.bodyGraphic = AnimationFactory:newStaticSprite('treasure-chest-body')
    self.lidGraphic = AnimationFactory:newStaticSprite('treasure-chest-lid')

    self.width = math.max(
      self.bodyGraphic:getWidth(),
      self.lidGraphic:getWidth()
    )
    self.height = 27

    Gui.create({
      group = 'all',
      x = parent.x - parent.width/2,
      y = parent.y - 15,
      width = parent.width,
      height = parent.height,
      getMousePosition = function(self)
        local camera = require 'components.camera'
        local mx, my = camera:getMousePosition()
        return mx, my
      end,
      onClick = function(self)
        print('chest clicked')
        local tween = require 'modules.tween'
        parent.tween = tween.new(1, parent, {lidOffsetY = -200}, tween.easing.inExpo)
      end
    }):setParent(self)
  end,
  update = function(self, dt)
    if self.tween then
      local complete = self.tween:update(dt)
    end
  end,
  draw = function(self)
    self.bodyGraphic:draw(self.x, self.y)
    self.lidGraphic:draw(self.x, self.y + self.lidOffsetY)
  end
})

Component.create({
  id = 'TreasureChestTest',
  init = function(self)
    Component.addToGroup(self, 'all')
    TreasureChest.create({
      id = 'mockTreasureChest'
    })
  end,
})