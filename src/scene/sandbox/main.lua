local groups = require 'components.groups'

local SandboxBlueprint = {}

-- SCENES
local spritePositioning = require 'scene.sandbox.sprite-positioning'
local ai = require 'scene.sandbox.ai.test-scene'

local state = {
  activeScene = ai
}

function SandboxBlueprint.init()
  state.activeScene.create()
end

return groups.debug.createFactory(SandboxBlueprint)