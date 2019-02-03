local cargo = require 'modules.cargo'
local utils = cargo.init('utils')
local graph = utils.graph
local Node, Model = graph.Node, graph.Model

local nodeSystem = Node:getSystem('test')
local n1 = nodeSystem:newNode()
local n2 = nodeSystem:newNode()
assert(n1 ~= n2, 'node ids should not be the same')

local modelSystem = Model:getSystem('test')
local linkId1 = modelSystem:addLink(n1, n2)
modelSystem:reset()
assert(
  modelSystem:getLinkByLinkId(linkId1) == nil,
  'old link should be gone after a reset'
)

local linkId2 = modelSystem:addLink(n1, n2)
assert(linkId1 == linkId2, 'ids should be identical after resetting')

nodeSystem:reset()
assert(
  not nodeSystem:get(n1) and
  not nodeSystem:get(n2),
  'node should be removed from reset'
)