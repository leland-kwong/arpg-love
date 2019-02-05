local msgBus = require 'components.msg-bus'
require 'modules.log-db.error-log'

-- load up user settings on game start
local userSettingsState = require 'config.user-settings.state'
userSettingsState.load()

local config = require 'config.config'
if config.isDevelopment then
  require 'repl'

  local Console = require 'modules.console.console'
  local console = Console.create()

  LiveReload:setOptions({
    enabled = true
  })
  msgBus.on('UPDATE', function(dt)
    LiveReload:update(dt)
  end)
end

require 'scene.scene-main'

local MapPointerWorld = require 'components.hud.map-pointer'
MapPointerWorld.create({
  id = 'hudPointerWorld'
})

local Component = require 'modules.component'
local drawOrders = require 'modules.draw-orders'
local LightWorld = require('components.light-world')
local camera = require 'components.camera'

local RootScene = require 'scene.sandbox.main'
RootScene.create()

require 'components.groups.dungeon-test'
require 'components.groups.game-world'
require 'modules.auto-visibility'
require 'components.map-text'
require 'components.status-icons'
require 'components.hud.player-position-indicator'
require 'main.onload.news-dialog'
require 'components.groups.dungeon-test'
require 'components.groups.game-world'
require 'components.groups.tether-position'


local newLightWorld = LightWorld.create({
  id = 'lightWorld',
  group = Component.groups.all,
  drawOrder = function()
    return drawOrders.LightWorldDraw
  end
})

local Notifier = require 'components.hud.notifier'
local config = require 'config.config'
local notifierWidth, notifierHeight = 250, 200
local notifier = Notifier.create({
  x = 0,
  y = 0,
  h = notifierHeight,
  w = notifierWidth
})

Component.create({
  init = function(self)
    Component.addToGroup(self, 'firstLayer')
  end,
  update = function(self, dt)
    notifier.x, notifier.y =
      love.graphics.getWidth()/config.scale - notifier.w,
      love.graphics.getHeight()/config.scale - notifier.h

    local gravForce = require 'components.groups.gravitational-force'
    gravForce(dt)
  end
})

local ActionError = require 'components.hud.action-error'
local ActionErrorTextLayer = require 'components.gui.gui-text'.create({
  font = require 'components.font'.primary.font
})
ActionError.create({
  textLayer = ActionErrorTextLayer
})