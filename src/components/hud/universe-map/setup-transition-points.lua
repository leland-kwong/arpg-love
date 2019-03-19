local Grid = require 'utils.grid'
local F = require 'utils.functional'
local Graph = require 'utils.graph'

local function getExitFromBlock(levelDefinition)
  return F.filter(
    F.find(levelDefinition.layers, 'name', 'transition-points').objects,
    function(v)
      return v.type == 'levelExit'
    end
  )
end

local function linkOrderByNode(node, link)
  local n1, n2 = unpack(link)
  if n1 == node then
    return n1, n2
  end
  return n2, n1
end

return function(levelDefinition, universeNodeId, links, seed, maxRetries)
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
    local linkId = linksAsList[i]
    local linkRef = Graph:getSystem('universe'):getLinkById(linkId)
    local n1, n2 = linkOrderByNode(universeNodeId, linkRef.nodes)
    local direction = (n1 < n2) and 3 or 1
    local done = false
    for i=1, #exitsRemainingToPrepare do
      if (not done) then
        local exit = exitsRemainingToPrepare[i]
        if exit.properties.direction == direction then
          done = true
          table.remove(exitsRemainingToPrepare, i)
          local nodeRef = Graph:getSystem('universe'):getNode(n2)
          exitDefinitions[exit.id] = {
            transitionLinkId = linkId,
            layoutType = nodeRef.level
          }
        end
      end
    end
  end

  return exitDefinitions
end