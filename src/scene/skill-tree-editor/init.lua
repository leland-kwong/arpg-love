local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'
local msgBusMainMenu = require 'components.msg-bus-main-menu'
local SkillTreeEditor = require 'scene.skill-tree-editor.editor'

local nodeValueOptions = {
  [1] = {
    name = 'attack speed',
    value = 1
  },
  [2] = {
    name = 'bonus damage',
    value = 0.2
  },
  [3] = {
    name = 'lightning rod',
    value = 'lightning damage',
    type = 'keystone'
  }
}

local Scene = {}

function Scene.init(self)
  SkillTreeEditor.create(self.initialProps)
end

msgBusMainMenu.send(msgBusMainMenu.MENU_ITEM_ADD, {
  name = 'passive tree',
  value = function()
    msgBus.send(msgBus.SCENE_STACK_PUSH, {
      scene = Component.createFactory(Scene),
      props = {
        nodeValueOptions = nodeValueOptions,
        nodes = SkillTreeEditor.loadState()
      }
    })
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end
})