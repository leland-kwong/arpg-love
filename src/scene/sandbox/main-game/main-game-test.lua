local Component = require 'modules.component'
local groups = require 'components.groups'
local SceneMain = require 'scene.scene-main'
local config = require 'config'

local MainGameTest = {
  group = groups.all
}

local function modifyLevelRequirements()
  local base = 10
  for i=0, 1000 do
    config.levelExperienceRequirements[i + 1] = i * base
  end
end

function MainGameTest.init(self)
  modifyLevelRequirements()
  SceneMain.create():setParent(self)
end

return Component.createFactory(MainGameTest)

