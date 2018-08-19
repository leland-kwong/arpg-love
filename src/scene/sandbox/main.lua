local Component = require 'modules.component'
local groups = require 'components.groups'

local SandboxBlueprint = {
  group = groups.debug
}

function SandboxBlueprint.init()
  -- SCENES
  local mainGame = require 'scene.sandbox.main-game.main-game-test'
  local spritePositioning = require 'scene.sandbox.sprite-positioning'
  local ai = require 'scene.sandbox.ai.test-scene'
  local gui = require 'scene.sandbox.gui.test-scene'
  local particleFx = require 'scene.sandbox.particle-fx.particle-test'

  local state = {
    activeScene = mainGame
  }

  state.activeScene.create()
end

return Component.createFactory(SandboxBlueprint)