--[[
  Utility library for generating a graph datastructure via nodes and links.
]]

local Vec2 = require 'modules.brinevector'

local development = false

local createId = function(self)
  self._idCounter = (self._idCounter or 0) + 1
  return self._idCounter
end

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

  local shouldClearReferenceList = list.numLinks == 0
  if shouldClearReferenceList then
    self.linksByNode[node1] = nil
  end
end

local modelMt = {
  createId = createId,
  addLink = function(self, node1, node2)
    local link = {node1, node2}
    local linkId = self:createId()
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

local nodeMt = {
  position = Vec2()
}
nodeMt.__index = nodeMt

local Node = {
  _systems = {},
  setDevelopment = function(isDev)
    development = isDev
  end,
  createId = createId,
  -- returns an id for the node
  create = function(self, system, props)
    assert(type(system) == 'string', 'a system name must be provided')

    local node = setmetatable(props or {}, nodeMt)

    self._systems[system] = self._systems[system] or {
      nodes = {},
      count = 0
    }
    local systemList = self._systems[system]
    systemList.count = systemList.count + 1
    local id = node._id or systemList.count
    node._id = id
    systemList.nodes[id] = node
    return id
  end,
  get = function(self, system, id)
    local systemList = self._systems[system]
    return systemList and systemList.nodes[id] or nil
  end,
  delete = function(self, id)
    local systemList = self._systems[system]
    if systemList then
      systemList.nodes[id] = nil
    end
    return self
  end,
  clearSystem = function(self, system)
    self._systems[system] = nil
  end
}

local Model = {
  createId = createId,
  modelList = {},
  create = function(self, options)
    local model = setmetatable({
      _id = self:createId(),
      linksByNode = {},
      links = {}
    }, modelMt)
    self.modelList[model._id] = model
    return model
  end,
}

return {
  Node = Node,
  Model = Model
}