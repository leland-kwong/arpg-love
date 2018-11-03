local Component = require 'modules.component'
local GuiDialog = require 'components.gui.gui-dialog'
local releaseNotes = love.filesystem.read('release-notes.md')
local Position = require 'utils.position'
local Color = require 'modules.color'

Component.create({
  init = function(self)
    Component.addToGroup(self, 'gui')

    self.dialog = GuiDialog.create({
      x = 200,
      y = 100,
      width = 400,
      height = 300,
      padding = 10,
      title = 'New Version',
      titleColor = Color.YELLOW,
      text = releaseNotes,
      drawOrder = function()
        return require 'modules.draw-orders'.Dialog
      end,
      onClose = function()
        self:delete(true)
      end
    })
  end,

  update = function(self)
    local d = self.dialog
    local vWidth, vHeight = love.graphics.getDimensions()
    local x, y = Position.boxCenterOffset(d.width, d.height, vWidth/2, vHeight/2)
    d.x, d.y = x, y
  end
})