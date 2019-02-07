local Component = require 'modules.component'
local AnimationFactory = LiveReload 'components.animation-factory'
local Font = require 'components.font'
local GuiText = require 'components.gui.gui-text'
local Color = require 'modules.color'

local themes = {
  checkPointUnlocked = {
    title = {Color.rgba255(185,245,44)},
    body = {Color.rgba255(99,199,77)}
  },
  levelUp = {
    title = {Color.rgba255(254,174,52)},
    body = {Color.rgba255(247,118,34)}
  }
}

local BigNotifier = {
  themes = themes,
  group = 'hud',
  color = {0,0,0},
  opacity = 1,
  scale = 1,
  duration = 1.5,
  hideDelay = 3,
  clock = 0,
  text = {
    title = nil,
    body = ''
  },
  init = function(self)
    Component.addToGroup(self, 'gameWorld')
  end,
  update = function(self, dt)
    self.clock = self.clock + dt
    if self.clock >= self.hideDelay then
      self.tween = self.tween or Component.animate(self, {
        opacity = 0,
        scale = 1.2
      }, self.duration, 'outQuad', function()
        self:delete()
      end)
    end
    local camera = require 'components.camera'
    local w,h = camera:getSize(true)
    self.x, self.y = w/2, h/2 - self.h - 30
  end,
  draw = function(self)
    xpcall(function()
      love.graphics.push()
      love.graphics.scale(self.scale)
      local scaleDiff = (1 - self.scale)/self.scale
      love.graphics.translate(self.x * scaleDiff, self.y * scaleDiff)

      local opacity = self.opacity
      love.graphics.setColor(Color.multiplyAlpha(self.color, opacity))
      local background = AnimationFactory:newStaticSprite('gui-gradient-background')
      background:draw(self.x, self.y, 0, self.w/100, self.h)

      local textOffsetY = -10
      local titleW,titleH = 0,0
      if self.text.title then
        local font = Font.secondary.font
        titleW,titleH = GuiText.getTextSize(self.text.title, font)
        love.graphics.setColor(1,1,1,opacity)
        love.graphics.setFont(font)
        love.graphics.printf(self.text.title, self.x - self.w/2, self.y + textOffsetY, self.w, 'center')
      end

      if self.text.body then
        local font = Font.primary.font
        local w,h = GuiText.getTextSize(self.text.body, font)
        love.graphics.setColor(1,1,1,opacity)
        love.graphics.setFont(font)
        love.graphics.printf(self.text.body, self.x - self.w/2, self.y + titleH + 2 + textOffsetY, self.w, 'center')
      end

      love.graphics.pop()
    end, function(err)
      print(err)
    end)
  end,
  drawOrder = function()
    return 10
  end
}

local Factory = Component.createFactory(BigNotifier)

-- Factory.create({
--   id = 'BigNotifierTest',
--   w = 260,
--   h = 50,
--   duration = 1,
--   text = {
--     title = 'Checkpoint',
--     body = 'Location 1-1 now available in map'
--   }
-- })

return Factory