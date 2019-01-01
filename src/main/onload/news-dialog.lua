local Component = require 'modules.component'
local userSettings = require 'config.user-settings'
local userSettingsState = require 'config.user-settings.state'

Component.create({
  init = function(self)
    Component.addToGroup(self, 'gui')

    local previousVersion = userSettings.previousVersion
    local getVersion = require 'modules.get-version'
    local currentVersion = getVersion()
    local isNewVersion = previousVersion ~= currentVersion

    -- show news dialog
    if isNewVersion then
      require 'main.onload.handle-version-change'()
        :next(function()
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
          local msgBus = require 'components.msg-bus'
          msgBus.send(msgBus.LATEST_NEWS_TOGGLE, true)
        end, function(err)
          error(err)
        end)
    else
      self:delete()
    end
  end

  -- update = function(self)
  --   self.dialog = self.dialog or createDialog(self)
  --   local d = self.dialog
  --   if d then
  --     local vWidth, vHeight = love.graphics.getDimensions()
  --     local x, y = Position.boxCenterOffset(d.width, d.height, vWidth/2, vHeight/2)
  --     d.x, d.y = x, y
  --   end
  -- end
})