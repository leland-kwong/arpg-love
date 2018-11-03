local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local BeamStrike = require 'components.abilities.beam-strike'

local SkewRotateTest = {
  group = groups.gui
}

function SkewRotateTest.init(self)
  self.clock = 0
end

local impactDelay = 1

function SkewRotateTest.update(self, dt)
  if self.clock == 0 then
    for i=1, math.random(3, 5) do
      BeamStrike.create({
        x = math.random(1, 6) * 50,
        y = math.random(1, 5) * 50,
        delay = impactDelay + (i * 0.15),
        onHit = function(self)
          consoleLog(self.x, self.y)
        end
      })
    end
  end
  self.clock = self.clock + dt
  if (self.clock >= impactDelay * 2) then
    self.clock = 0
  end
end

local Factory = Component.createFactory(SkewRotateTest)

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'skew and rotate test',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Factory
    })
  end
})