local GuiText = require 'components.gui.gui-text'
local Component = require 'modules.component'

Component.create({
  id = 'BreakScreen',
  enabled = true,
  init = function(self)
    Component.addToGroup(self, 'all')

    if not self.enabled then
      return
    end

    self.textLayer = GuiText.create({
      font = require 'components.font'.secondaryLarge.font
    })
  end,
  draw = function(self)
    local Color = require 'modules.color'
    self.textLayer:add('Dinner. Be back @ 930PM PST', Color.YELLOW, 150, 150)
  end
})