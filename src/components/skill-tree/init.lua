local Component = require 'modules.component'
local SkillTreeEditor = require 'scene.skill-tree-editor.editor'

local SkillTree = {}

function SkillTree.init(self)
  Component.addToGroup(self, 'gui')

  local nodeData = SkillTreeEditor.loadState()
end

return Component.createFactory(SkillTree)