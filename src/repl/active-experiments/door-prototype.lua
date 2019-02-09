local Door = LiveReload 'repl.components.door'
local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local O = require 'utils.object-utils'

msgBus.send('TOGGLE_MAIN_MENU', false)
