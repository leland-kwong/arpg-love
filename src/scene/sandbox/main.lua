local groups = require 'components.groups'

local SandboxBlueprint = {}

function SandboxBlueprint.init()
  -- SCENES
  local spritePositioning = require 'scene.sandbox.sprite-positioning'
  local ai = require 'scene.sandbox.ai.test-scene'

  local state = {
    activeScene = ai
  }

  state.activeScene.create()
end

return groups.debug.createFactory(SandboxBlueprint)