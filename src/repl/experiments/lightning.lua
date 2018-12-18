local Template = require 'repl.template'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local lightBlur = love.graphics.newImage('built/images/light-blur.png')
local Vec2 = require 'modules.brinevector'

Component.create({
  id = 'lightning-generator-test',
  init = function(self)
    Template.create()

    self.listeners = {
      msgBus.on(msgBus.MOUSE_CLICKED, function(ev)
        local x, y = unpack(ev)
        Component.get('lightning-effect'):add({
          start = Vec2(150, 300),
          target = Vec2(x, y),
          thickness = 2
        })
      end)
    }

    local dynamicRequire = require 'utils.dynamic-require'
    dynamicRequire 'components.effects.lightning'
  end,

  draw = function()
    local bgColor = {0.2,0.2,0.2}
    love.graphics.clear(bgColor)
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})