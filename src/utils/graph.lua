--[[
  Utility library for generating a graph datastructure via nodes and links.
]]

local Vec2 = require 'modules.brinevector'
local O = require 'utils.object-utils'

local development = false

local nodeMt = {
  position = Vec2()
}
nodeMt.__index = nodeMt

local setNodeSystemDefaultProps = function(nodeSystem)
  return O.assign(nodeSystem, {
    nodes = {},
    counter = 0
  })
end

local nodeSystemMt = {
  newNode = function(self, props)
    local node = setmetatable(props or {}, nodeMt)
    self.counter = self.counter + 1
    local id = node._id or self.counter
    node._id = id
    self.nodes[id] = node
    return id
  end,
  get = function(self, id)
    return self.nodes[id]
  end,
  reset = function(self)
    setNodeSystemDefaultProps(self)
    return self
  end
}
nodeSystemMt.__index = nodeSystemMt

local Node = {
  _systems = {},
  setDevelopment = function(isDev)
    development = isDev
  end,
  -- creates the system if needed, otherwise returns an existing system
  getSystem = function(self, system)
    assert(type(system) == 'string', 'a system name must be provided')

    self._systems[system] = self._systems[system] or
      setNodeSystemDefaultProps(setmetatable({}, nodeSystemMt))
    local nodeSystem = self._systems[system]
    return nodeSystem
  end,

  release = function(self, system)
    self._systems[system] = nil
  end
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

  local shouldClearReferenceList = list.numLinks == 0
  if shouldClearReferenceList then
    self.linksByNode[node1] = nil
  end
end

local setModelDefaultProps = function(model)
  return O.assign(model, {
    counter = 0,
    linksByNode = {},
    links = {}
  })
end

local modelMt = {
  addLink = function(self, node1, node2)
    local nodeSystem = Node:getSystem(self.system)
    assert(
      nodeSystem:get(node1) and nodeSystem:get(node2),
      'one of the nodes in the link no longer exists in the node system'
    )

    self.counter = self.counter + 1
    local link = {node1, node2}
    local linkId = self.counter
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
  end,

  reset = function(self)
    setModelDefaultProps(self)
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

local Model = {
  _systems = {},
  getSystem = function(self, system)
    local model = self._systems[system]
    if (not model) then
      model = setModelDefaultProps(setmetatable({
        system = system
      }, modelMt))
      self._systems[system] = model
    end
    return model
  end,

  release = function(self, system)
    self._systems[system] = nil
  end
}

return {
  Node = Node,
  Model = Model
}