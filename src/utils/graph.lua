--[[
  Utility library for generating a graph datastructure via nodes and links.
]]

local O = require 'utils.object-utils'

local development = false

local function addLinkReference(self, linkId, node1, node2)
  local list = self.linksByNodeId[node1]
  if (not list) then
    list = {
      links = {},
      numLinks = 0
    }
    self.linksByNodeId[node1] = list
  end
  list.links[node2] = linkId
  list.numLinks = list.numLinks + 1
end

local function removeLinkReference(self, node1, node2)
  local list = self.linksByNodeId[node1]
  local linkId = list and list.links[node2]
  if (not linkId) then
    return
  end
  list.links[node2] = nil
  list.numLinks = list.numLinks - 1

  local shouldClearReferenceList = list.numLinks == 0
  if shouldClearReferenceList then
    self.linksByNodeId[node1] = nil
  end

  return linkId
end

local setNodeSystemDefaultProps = function(nodeSystem)
  return O.assign(nodeSystem, {
    nodesById = {},
    nodeCounter = 0,

    linksByNodeId = {},
    linksById = {},
    linkCounter = 0
  })
end

local nodeSystemMt = {
  setNode = function(self, id, props)
    local idType = type(id)
    assert(
      (idType == 'string') or (idType == 'number'),
      'id must be a string or number'
    )

    local node = props or ''
    self.nodeCounter = self.nodeCounter + 1
    self.nodesById[id] = node
    return self
  end,

  newLink = function(self, node1, node2, data)
    assert(
      self:getNode(node1) and self:getNode(node2),
      '[graph:newLink] a node is missing in the system'
    )

    self.linkCounter = self.linkCounter + 1
    local link = setmetatable({
      nodes = {node1, node2},
      data = data or nil
    }, linkMt)
    local linkId = self.linkCounter
    self.linksById[linkId] = link

    addLinkReference(self, linkId, node1, node2)
    addLinkReference(self, linkId, node2, node1)

    return self
  end,

  removeNode = function(self, node)
    local links = self:getNodeLinks(node)
    for _,linkId in pairs(links) do
      local linkRef = self:getLinkById(linkId)
      local node1, node2 = linkRef.nodes[1], linkRef.nodes[2]
      self:removeLink(node1, node2)
    end
    self.nodesById[node] = nil
    return self
  end,

  removeLink = function(self, node1, node2)
    local linkId = removeLinkReference(self, node1, node2)
    if (not linkId) then
      return self
    end

    removeLinkReference(self, node2, node1)
    self.linksById[linkId] = nil
    return self
  end,

  -- returns the link reference
  getLinkById = function(self, linkId)
    return self.linksById[linkId]
  end,

  -- returns a table of linkIds for a given node {[nodeId] = [linkId], ...}
  getNodeLinks = function(self, node)
    local list = self.linksByNodeId[node] or O.EMPTY
    return list.links or O.EMPTY
  end,

  -- returns an iterator
  getAllNodes = function(self)
    return coroutine.wrap(function()
      for nodeId,nodeRef in pairs(self.nodesById) do
        coroutine.yield(nodeId, nodeRef)
      end
    end)
  end,

  -- returns an iterator
  getAllLinks = function(self)
    return coroutine.wrap(function()
      for linkId,linkRef in pairs(self.linksById) do
        coroutine.yield(linkId, linkRef)
      end
    end)
  end,

  -- iterate over all links in the system
  forEachLink = function(self, callback)
    for linkId,link in pairs(self.linksById) do
      callback(linkId, link)
    end
    return self
  end,

  getNode = function(self, id)
    return self.nodesById[id]
  end,

  clear = function(self)
    setNodeSystemDefaultProps(self)
    return self
  end
}
nodeSystemMt.__index = nodeSystemMt

local Graph = {
  _systems = {},
  setDevelopment = function(isDev)
    development = isDev
  end,
  -- creates the system if needed, otherwise returns an existing system
  getSystem = function(self, system)
    assert(type(system) == 'string', 'a system name must be provided')

    local nodeSystem = self._systems[system]
    if (not nodeSystem) then
      nodeSystem = setNodeSystemDefaultProps(
        setmetatable({
          systemName = system,
          idFormat = system..'-%d'
        }, nodeSystemMt)
      )
      self._systems[system] = nodeSystem
    end
    return nodeSystem
  end,

  release = function(self, system)
    self._systems[system] = nil
  end
}

return Graph