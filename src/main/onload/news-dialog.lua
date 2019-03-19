local Component = require 'modules.component'
local userSettings = require 'config.user-settings'
local userSettingsState = require 'config.user-settings.state'
local msgBus = require 'components.msg-bus'

Component.create({
  id = 'newsDialog',
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
          msgBus.send(msgBus.LATEST_NEWS_TOGGLE, true)
          self:delete()
        end, function(err)
          error(err)
          self:delete()
        end)
    else
      self:delete()
      msgBus.send('PLAY_GAME_MENU_TOGGLE')
    end
  end
})