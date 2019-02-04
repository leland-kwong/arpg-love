local Vec2 = require 'modules.brinevector'
local Graph = require 'utils.graph'

return function(actions)
  local nodeSystem = Graph:getSystem('universe'):clear()

  local level1_1 = nodeSystem:newNode({
    position = Vec2(20, 30),
    region = 'aureus',
    level = '1-1',
    labelPosition = 'top'
  })

  local level1_2 = nodeSystem:newNode({
    position = Vec2(
      nodeSystem:getNode(level1_1).position.x + 25,
      nodeSystem:getNode(level1_1).position.y
    ),
    region = 'aureus',
    level = '1-2',
    labelPosition = 'top'
  })
  nodeSystem:newLink(level1_1, level1_2)

  local level1_3 = nodeSystem:newNode({
    position = Vec2(
      nodeSystem:getNode(level1_2).position.x + 25,
      nodeSystem:getNode(level1_2).position.y
    ),
    region = 'aureus',
    level = '1-3',
    labelPosition = 'top'
  })
  nodeSystem:newLink(level1_2, level1_3)

  local level2_1 = nodeSystem:newNode({
    position = Vec2(
      nodeSystem:getNode(level1_3).position.x + 50,
      nodeSystem:getNode(level1_3).position.y + 20
    ),
    level = 's-1',
    region = 'saria'
  })
  nodeSystem:newLink(level1_3, level2_1)

  local level2_2 = nodeSystem:newNode({
    position = Vec2(
      nodeSystem:getNode(level2_1).position.x + 30,
      nodeSystem:getNode(level2_1).position.y
    ),
    level = 's-2',
    region = 'saria'
  })
  nodeSystem:newLink(level2_1, level2_2)

  local level2_3 = nodeSystem:newNode({
    position = Vec2(
      nodeSystem:getNode(level2_2).position.x + 15,
      nodeSystem:getNode(level2_2).position.y + 25
    ),
    level = 's-3',
    labelPosition = 'right',
    region = 'saria'
  })
  nodeSystem:newLink(level2_2, level2_3)

  local level2_4 = nodeSystem:newNode({
    position = Vec2(
      nodeSystem:getNode(level2_2).position.x - 15,
      nodeSystem:getNode(level2_2).position.y + 25
    ),
    level = 's-4',
    labelPosition = 'left',
    region = 'saria'
  })
  nodeSystem:newLink(level2_2, level2_4)

  local avgPos = (nodeSystem:getNode(level1_2).position + nodeSystem:getNode(level2_1).position) / 2
  local secretLevel1 = nodeSystem:newNode({
    position = Vec2(
      avgPos.x - 15,
      avgPos.y + 20
    ),
    level = 'secret-1',
    -- secret = true,
    region = ''
  })
  nodeSystem:newLink(level2_4, secretLevel1)

  local avgPos = (nodeSystem:getNode(level1_2).position + nodeSystem:getNode(level2_2).position) / 2
  local secretLevel1 = nodeSystem:newNode({
    position = Vec2(
      avgPos.x + 5,
      avgPos.y - 32
    ),
    level = 'secret-2',
    -- secret = true,
    region = ''
  })
  nodeSystem:newLink(secretLevel1, level2_1)

  actions.newGraph('universe')

  return nodeSystem
end