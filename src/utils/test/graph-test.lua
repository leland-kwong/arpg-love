local O = require 'utils.object-utils'

local ok, err = pcall(function()
  local cargo = require 'modules.cargo'
  local utils = cargo.init('utils')
  local Graph = utils.graph

  local system = Graph:getSystem('test')

  system:setNode(1)
  assert(system:getNode(1) ~= nil, 'node with number id should be created')

  system:setNode(1, 'foo')
  assert(system:getNode(1) == 'foo', 'node value should be set')

  system:setNode('foo')
  assert(system:getNode('foo') ~= nil, 'node with string id should be created')

  system
    :setNode(1)
    :setNode(2)
    :newLink(1, 2)
    :removeLink(1, 2)
  assert(O.isEmpty(system:getNodeLinks(1)), 'link should be removed')

  system:clear()
  assert(
    not system:getNode(1) and
    not system:getNode(2),
    'node should be removed from reset'
  )

  -- REMOVE NODE WITH LINKS
  local system = Graph:getSystem('test'):clear()
  system
    :setNode(1)
    :setNode(2)
    :setNode(3)
    :newLink(1, 2)
    :newLink(1, 3)
    :removeNode(1)

  assert(
    O.isEmpty(system:getNodeLinks(1)) and
    O.isEmpty(system:getNodeLinks(2)),
    'all links connected to a removed node should be removed'
  )
end)

if (not ok) then
  print(err)
end