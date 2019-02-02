local Vec2 = require 'modules.brinevector'
local Model = require 'utils.graph'.Model

return function(actions, Node)
  local model = Model:create()

  local level1 = Node:create({
    position = Vec2(20, 30),
    region = 'aureus',
    level = 'a-1',
    labelPosition = 'top'
  })

  local level2 = Node:create({
    position = Vec2(
      Node:get(level1).position.x + 40,
      Node:get(level1).position.y
    ),
    region = 'aureus',
    level = 'a-2',
    labelPosition = 'top'
  })
  model:addLink(level1, level2)

  local level3 = Node:create({
    position = Vec2(
      Node:get(level2).position.x + 50,
      Node:get(level2).position.y + 20
    ),
    level = 's-1',
    region = 'saria'
  })
  model:addLink(level2, level3)

  local level4 = Node:create({
    position = Vec2(
      Node:get(level3).position.x + 30,
      Node:get(level3).position.y
    ),
    level = 's-2',
    region = 'saria'
  })
  model:addLink(level3, level4)

  local level5 = Node:create({
    position = Vec2(
      Node:get(level4).position.x + 15,
      Node:get(level4).position.y + 25
    ),
    level = 's-3',
    labelPosition = 'right',
    region = 'saria'
  })
  model:addLink(level4, level5)

  local level6 = Node:create({
    position = Vec2(
      Node:get(level4).position.x - 15,
      Node:get(level4).position.y + 25
    ),
    level = 's-4',
    labelPosition = 'left',
    region = 'saria'
  })
  model:addLink(level4, level6)

  local avgPos = (Node:get(level2).position + Node:get(level3).position) / 2
  local secretLevel1 = Node:create({
    position = Vec2(
      avgPos.x - 15,
      avgPos.y + 20
    ),
    secret = true,
    region = ''
  })
  model:addLink(level2, secretLevel1)
  model:addLink(level1, secretLevel1)

  local avgPos = (Node:get(level2).position + Node:get(level4).position) / 2
  local secretLevel2 = Node:create({
    position = Vec2(
      avgPos.x + 5,
      avgPos.y - 32
    ),
    secret = true,
    region = ''
  })
  model:addLink(secretLevel2, level3)

  actions.newGraph(model)

  return model
end