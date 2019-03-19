local Component = require 'modules.component'
local groups = require 'components.groups'

--[[
  A generic node with no built-in functionality.
]]
return Component.createFactory({
  group = groups.gui
})