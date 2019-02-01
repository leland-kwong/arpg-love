local Grid = require 'utils.grid'

local NIL = '_nil'
return function(blocks, node, links, seed)
  math.randomseed(seed or os.clock())

  local numCols = 4

  local level = {}
  local numExits = 0
  local blocksWithEntrances = {}

  local F = require 'utils.functional'
  local numBlocks = F.reduce(blocks, function(count, v)
    return count + (v ~= NIL and 1 or 0)
  end, 0)
  local linksAsList = F.reduce(F.keys(links), function(list, nodeId)
    local linkId = links[nodeId]
    table.insert(list, linkId)
    return list
  end, {})
  local numLinks = #linksAsList
  local done = false
  local allExitsSetup = false
  while (not done) do
    local i = 1
    while ((i < #blocks) and (not done)) do
      local blockType = blocks[i]
      if blockType ~= NIL and (not blocksWithEntrances[i]) then
        local x,y = Grid.getCoordinateByIndex(numCols, i)
        local hasExit = (not allExitsSetup) and (math.random(0, numBlocks) == 0)
        local blockData = {
          exitLink = hasExit and table.remove(linksAsList) or nil,
          blockType = blockType
        }
        if hasExit then
          numExits = numExits + 1
          blocksWithEntrances[i] = true
        end
        Grid.set(level, x, y, blockData)
      end
      allExitsSetup = numExits >= numLinks
      i = i + 1
    end
    done = allExitsSetup
  end

  return {
    nodeId = node,
    blocks = level
  }
end