local SceneMenu = require 'scene.scene-menu'
local Component = require 'modules.component'
local groups = require 'components.groups'

local Sandbox = {
  group = groups.debug
}

function Sandbox.init()
  SceneMenu.create({
    scenes = {
      ['main game'] = 'scene.sandbox.main-game.main-game-test',
      ['sprite positioning'] = 'scene.sandbox.sprite-positioning',
      ai = 'scene.sandbox.ai.test-scene',
      gui = 'scene.sandbox.gui.test-scene',
      ['particle fx'] = 'scene.sandbox.particle-fx.particle-test',
    }
  })
end

return Component.createFactory(Sandbox)