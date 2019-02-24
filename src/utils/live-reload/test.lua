local LiveReload = require 'utils.live-reload'

local tm1 = require 'utils.live-reload.test-module'
local tm2 = LiveReload('utils.live-reload.test-module')
assert(tm1 ~= tm2, 'live reloaded module should be different from original')

local tm3 = require 'utils.live-reload.test-module'
assert(tm1 == tm3, 'live reload should not change the original loaded module')