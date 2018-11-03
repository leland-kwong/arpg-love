local Component = require 'modules.component'
local GuiDialog = require 'components.gui.gui-dialog'
local releaseNotes = love.filesystem.read('release-notes.md')
local Position = require 'utils.position'
local Color = require 'modules.color'
local userSettingsState = require 'config.user-settings.state'

local function createDialog(self)
  return GuiDialog.create({
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
      self:setDisabled(true)
      self.dialog = nil
    end
  })
end

Component.create({
  id = 'newsDialog',
  init = function(self)
    Component.addToGroup(self, 'gui')

    local settingsData = userSettingsState.load()
    local previousVersion = settingsData.previousVersion
    local getVersion = require 'modules.get-version'
    local currentVersion = getVersion()
    local isNewVersion = previousVersion ~= currentVersion
    -- show news dialog
    if isNewVersion then
      require 'main.onload.handle-version-change'()
      userSettingsState.set(function(settings)
        settings.previousVersion = currentVersion
        return settings
      end):next(function()
        print(
          'save success'
        )
      end, function(err)
        print('error', err)
      end)
    else
      self:setDisabled(true)
    end
  end,

  update = function(self)
    self.dialog = self.dialog or createDialog(self)
    local d = self.dialog
    if d then
      local vWidth, vHeight = love.graphics.getDimensions()
      local x, y = Position.boxCenterOffset(d.width, d.height, vWidth/2, vHeight/2)
      d.x, d.y = x, y
    end
  end
})