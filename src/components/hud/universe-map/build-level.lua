local Grid = require 'utils.grid'
local F = require 'utils.functional'

local function getExitFromBlock(levelDefinition)
  return F.filter(
    F.find(levelDefinition.layers, 'name', 'transition-points').objects,
    function(v)
      return v.type == 'levelExit'
    end
  )
end

local function linkOrderByNode(node, link)
  local l1, l2 = unpack(link)
  if l1 == node then
    return l1, l2
  end
  return l2, l1
end

return function(levelDefinition, node, links, seed, maxRetries)
  math.randomseed(seed or os.clock())
  maxRetries = maxRetries or 100

  local numCols = levelDefinition.width

  local blocksWithEntrances = {}

  local linksAsList = F.reduce(F.keys(links), function(list, nodeId)
    local linkId = links[nodeId]
    table.insert(list, linkId)
    return list
  end, {})

  local exitsRemainingToPrepare = getExitFromBlock(levelDefinition)
  local exitDefinitions = {}

  for i=1, #linksAsList do
    local link = linksAsList[i]
    local l1, l2 = linkOrderByNode(node, link)
    local direction = (l1 < l2) and 3 or 1
    local done = false
    for i=1, #exitsRemainingToPrepare do
      if (not done) then
        local exit = exitsRemainingToPrepare[i]
        if exit.properties.direction == direction then
          done = true
          table.remove(exitsRemainingToPrepare, i)
          exitDefinitions[exit.id] = {
            x = exit.x,
            y = exit.y,
            link = {l1, l2}
          }
        end
      end
    end
  end

  print(Inspect(exitDefinitions))

  return {
    nodeId = node,
    exitPositions = exitPositions
  }
end