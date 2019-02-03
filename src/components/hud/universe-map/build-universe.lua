local Vec2 = require 'modules.brinevector'
local Model = require 'utils.graph'.Model

return function(actions, Node)
  local model = Model:create()
  Node:clearSystem('universe')

  local level1_1 = Node:create('universe', {
    position = Vec2(20, 30),
    region = 'aureus',
    level = '1-1',
    labelPosition = 'top'
  })

  local level1_2 = Node:create('universe', {
    position = Vec2(
      Node:get('universe', level1_1).position.x + 25,
      Node:get('universe', level1_1).position.y
    ),
    region = 'aureus',
    level = '1-2',
    labelPosition = 'top'
  })
  model:addLink(level1_1, level1_2)

  local level1_3 = Node:create('universe', {
    position = Vec2(
      Node:get('universe', level1_2).position.x + 25,
      Node:get('universe', level1_2).position.y
    ),
    region = 'aureus',
    level = '1-3',
    labelPosition = 'top'
  })
  model:addLink(level1_2, level1_3)

  local level2_1 = Node:create('universe', {
    position = Vec2(
      Node:get('universe', level1_3).position.x + 50,
      Node:get('universe', level1_3).position.y + 20
    ),
    level = 's-1',
    region = 'saria'
  })
  model:addLink(level1_3, level2_1)

  local level4 = Node:create('universe', {
    position = Vec2(
      Node:get('universe', level2_1).position.x + 30,
      Node:get('universe', level2_1).position.y
    ),
    level = 's-2',
    region = 'saria'
  })
  model:addLink(level2_1, level4)

  local level5 = Node:create('universe', {
    position = Vec2(
      Node:get('universe', level4).position.x + 15,
      Node:get('universe', level4).position.y + 25
    ),
    level = 's-3',
    labelPosition = 'right',
    region = 'saria'
  })
  model:addLink(level4, level5)

  local level6 = Node:create('universe', {
    position = Vec2(
      Node:get('universe', level4).position.x - 15,
      Node:get('universe', level4).position.y + 25
    ),
    level = 's-4',
    labelPosition = 'left',
    region = 'saria'
  })
  model:addLink(level4, level6)

  local avgPos = (Node:get('universe', level1_2).position + Node:get('universe', level2_1).position) / 2
  local secretLevel1 = Node:create('universe', {
    position = Vec2(
      avgPos.x - 15,
      avgPos.y + 20
    ),
    level = 'secret-1',
    -- secret = true,
    region = ''
  })
  model:addLink(level1_1, secretLevel1)

  local avgPos = (Node:get('universe', level1_2).position + Node:get('universe', level4).position) / 2
  local secretLevel1 = Node:create('universe', {
    position = Vec2(
      avgPos.x + 5,
      avgPos.y - 32
    ),
    level = 'secret-2',
    -- secret = true,
    region = ''
  })
  model:addLink(secretLevel1, level2_1)

  actions.newGraph(model)

  return model
end