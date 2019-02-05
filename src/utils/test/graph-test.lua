local O = require 'utils.object-utils'

local ok, err = pcall(function()

  local cargo = require 'modules.cargo'
  local utils = cargo.init('utils')
  local Graph = utils.graph

  local system = Graph:getSystem('test')
  local n1 = system:newNode()
  local n2 = system:newNode()
  local n3 = system:newNode()
  local n4 = system:newNode()
  assert(n1 ~= n2, 'node ids should not be the same')

  local linkId1 = system:newLink(n1, n2)
  system:removeLink(linkId1)
  assert(not system:getLinkById(linkId1), 'link id should be removed')

  system:clear()
  assert(
    not system:getNode(n1) and
    not system:getNode(n2),
    'node should be removed from reset'
  )

  -- REMOVE NODE WITH LINKS
  local system = Graph:getSystem('test'):clear()
  local n1 = system:newNode()
  local n2 = system:newNode()
  local n3 = system:newNode()
  local linkId1 = system:newLink(n1, n2)
  local linkId2 = system:newLink(n1, n3)

  system:removeNode(n1)
  assert(
    not system:getLinkById(linkId1) and
    not system:getLinkById(linkId2),
    'all links connected to a removed node should be removed'
  )

end)

if (not ok) then
  print(err)
end