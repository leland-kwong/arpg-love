local Vec2 = require 'modules.brinevector'

local development = false

local nodeMt = {
  position = Vec2()
}

local function addLinkReference(self, linkId, node1, node2)
  self.linksByNode[node1] = self.linksByNode[node1] or {
    links = {},
    numLinks = 0
  }
  local list = self.linksByNode[node1]
  list.links[node2] = linkId
  list.numLinks = list.numLinks + 1
end

local function removeLinkReference(self, node1, node2)
  local list = self.linksByNode[node1]
  list.links[node2] = nil
  list.numLinks = list.numLinks - 1

  -- clear out references
  if list.numLinks == 0 then
    self.linksByNode[node1] = nil
  end
end

local modelMt = {
  addLink = function(self, node1, node2)
    self.id = self.id + 1
    local linkId = self.id
    local link = {node1, node2}
    self.links[linkId] = link

    addLinkReference(self, linkId, node1, node2)
    -- also add reverse for reverse-lookup
    addLinkReference(self, linkId, node2, node1)

    return linkId
  end,

  removeLink = function(self, linkId)
    local node1, node2 = unpack(self:getLinkByLinkId(linkId))
    removeLinkReference(self, node1, node2)
    removeLinkReference(self, node2, node1)

    self.links[linkId] = nil
    return self
  end,

  -- returns the link reference
  getLinkByLinkId = function(self, linkId)
    return self.links[linkId]
  end,

  -- returns a table of links {[nodeId] = [linkId], ...}
  getLinksByNodeId = function(self, node, byReference)
    local list = self.linksByNode[node]
    local links = list and list.links
    if links and byReference then
      local refList = {}
      for _,id in pairs(links) do
        refList[id] = self:getLinkByLinkId(id)
      end
      return refList
    end
    return links
  end,

  hasNode = function(self, node)
    return self.linksByNode[node] ~= nil
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
  development = false,
  validator = function(self, node1, node2)
    return true
  end
}

local Node = {
  counter = 0,
  nodeList = {},
  modelList = {},
  setDevelopment = function(isDev)
    development = isDev
  end,
  createId = function(self)
    self.counter = self.counter + 1
    return self.counter
  end,
  -- returns an id for the node
  create = function(self, props)
    local node = setmetatable(props, nodeMt)
    local id = node.id or self:createId()
    node.id = id
    self.nodeList[id] = node
    return id
  end,
  createModel = function(self, options)
    local model = setmetatable({
      id = self:createId(),
      linksByNode = {},
      links = {}
    }, modelMt)
    self.modelList[model.id] = model
    return model
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