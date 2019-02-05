local Vec2 = require 'modules.brinevector'
local Graph = require 'utils.graph'

return function(actions)
  local uSystem = Graph:getSystem('universe'):clear()

  uSystem:setNode('1-1', {
    position = Vec2(20, 30),
    region = 'aureus',
    level = '1-1',
    labelPosition = 'top'
  })

  uSystem:setNode('1-2', {
    position = uSystem:getNode('1-1').position + Vec2(25, 0),
    region = 'aureus',
    level = '1-2',
    labelPosition = 'top'
  })
  uSystem:newLink('1-1', '1-2')

  uSystem:setNode('1-3', {
    position = uSystem:getNode('1-2').position + Vec2(25, 0),
    region = 'aureus',
    level = '1-3',
    labelPosition = 'top'
  })
  uSystem:newLink('1-2', '1-3')

  uSystem:setNode('2-1', {
    position = uSystem:getNode('1-3').position + Vec2(50, 20),
    level = 's-1',
    region = 'saria'
  })
  uSystem:newLink('1-3', '2-1')

  uSystem:setNode('2-2', {
    position = uSystem:getNode('2-1').position + Vec2(30, 0),
    level = 's-2',
    region = 'saria'
  })
  uSystem:newLink('2-1', '2-2')

  uSystem:setNode('2-3', {
    position = uSystem:getNode('2-2').position + Vec2(15, 25),
    level = 's-3',
    labelPosition = 'right',
    region = 'saria'
  })
  uSystem:newLink('2-2', '2-3')

  uSystem:setNode('2-4', {
    position = uSystem:getNode('2-2').position + Vec2(-15, 25),
    level = 's-4',
    labelPosition = 'left',
    region = 'saria'
  })
  uSystem:newLink('2-2', '2-4')

  local avgPos = (uSystem:getNode('1-2').position + uSystem:getNode('2-1').position) / 2
  uSystem:setNode('secret-1', {
    position = Vec2(
      avgPos.x - 15,
      avgPos.y + 20
    ),
    level = 'secret-1',
    -- secret = true,
    region = ''
  })
  uSystem:newLink('2-4', 'secret-1')

  local avgPos = (uSystem:getNode('1-2').position + uSystem:getNode('2-2').position) / 2
  uSystem:setNode('secret-2', {
    position = Vec2(
      avgPos.x + 5,
      avgPos.y - 32
    ),
    level = 'secret-2',
    -- secret = true,
    region = ''
  })
  uSystem:newLink('secret-2', '2-1')

  actions.newGraph('universe')

  return uSystem
end