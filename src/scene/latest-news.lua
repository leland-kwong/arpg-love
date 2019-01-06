local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Color = require 'modules.color'
local MenuManager = require 'modules.menu-manager'
local MenuList2 = require 'components.gui.menu-list-2'
local Fonts = require 'components.font'

return Component.createFactory({
  init = function(self)
    local parent = self
    Component.addToGroup(self, 'gui')
    MenuManager.clearAll()
    MenuManager.push(self)

    local dialog = MenuList2.create({
      id = 'LatestNewsDialog',
      x = self.x,
      y = self.y,
      height = parent.height,
      layoutItems = {},
      drawOrder = function()
        return require 'modules.draw-orders'.Dialog + 1
      end
    }):setParent(parent)

    dialog.layoutItems = {
      {
        Gui.create({
          onCreate = function(self)
            local markdownToLove2dString = require 'modules.markdown-to-love2d-string'
            self.content = markdownToLove2dString(love.filesystem.read('release-notes.md'))
          end,
          onUpdate = function(self)
            self.width = parent.width

            local GuiText = require 'components.gui.gui-text'
            local height = select(2, GuiText.getTextSize(self.content.plainText, Fonts.primary.font))
            self.height = height
          end,
          render = function(self)
            love.graphics.setColor(1,1,1)
            love.graphics.setFont(Fonts.primary.font)
            local padding = 5
            love.graphics.printf(self.content.formatted, self.x + padding, self.y + padding, self.width - padding*2)
          end
        })
      }
    }
  end,

  draw = function(self)
    local drawBox = require 'components.gui.utils.draw-box'
    drawBox(self)
  end,

  final = function(self)
    MenuManager.pop()
  end,

  drawOrder = function()
    return require 'modules.draw-orders'.Dialog
  end
})