local Component = require 'modules.component'
local GuiDialog = require 'components.gui.gui-dialog'
local Color = require 'modules.color'
local MenuManager = require 'modules.menu-manager'

return Component.createFactory({
  init = function(self)
    Component.addToGroup(self, 'gui')
    MenuManager.clearAll()
    MenuManager.push(self)

    local releaseNotes = love.filesystem.read('release-notes.md')
    GuiDialog.create({
      x = self.x,
      y = self.y,
      width = self.width,
      height = self.height,
      padding = 10,
      title = 'New Version',
      titleColor = Color.YELLOW,
      text = releaseNotes,
      drawOrder = function()
        return require 'modules.draw-orders'.Dialog
      end
    }):setParent(self)
  end,

  final = function(self)
    MenuManager.pop()
  end
})