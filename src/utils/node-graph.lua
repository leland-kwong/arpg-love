local Vec2 = require 'modules.brinevector'

local nodeMt = {
  position = Vec2()
}
local modelMt = {
  addLink = function(self, node1, node2)
    self.id = self.id + 1
    local link = {node1, node2}
    self.links[self.id] = link
    return self.id
  end,

  removeLink = function(self, linkId)
    self.links[linkId] = nil
    return self
  end,

  getLink = function(self, linkId)
    return self.links[linkId]
  end,

  hasNode = function(self, node)
    return self.nodes[node] ~= nil
  end,

  forEach = function(self, callback)
    for _,link in pairs(self.links) do
      callback(link)
    end
    return self
  end
}
modelMt.__index = modelMt
local modelDefaultOptions = {
  validator = function(self, node1, node2)
    return true
  end
}

local Node = {
  counter = 0,
  nodeList = {},
  -- returns an id for the node
  create = function(self, props)
    local node = setmetatable(props, nodeMt)
    self.counter = self.counter + 1
    local id = node.id or self.counter
    node.id = id
    self.nodeList[id] = node
    return id
  end,
  createModel = function(self, options)
    return setmetatable({
      id = 0,
      nodes = {},
      links = {}
    }, modelMt)
  end,
  get = function(self, id)
    return self.nodeList[id]
  end,
  delete = function(self, id)
    self.nodeList[id] = nil
    return self
  end,
  reduce = function(self, reducer, seed)
    local i = 1
    for id in pairs(self.nodeList) do
      seed = reducer(seed, id, i)
      i = i + 1
    end
    return seed
  end
}

return Node