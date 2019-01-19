local setProp = require 'utils.set-prop'
local uid = require 'utils.uid'
local collisionObject = require 'modules.collision'
local objectUtils = require 'utils.object-utils'
local noop = require 'utils.noop'

-- built-in defaults
local floor = math.floor
local baseProps = {
  x = 0,
  y = 0,
  z = 0, -- axis normal to the x-y plane
  angle = 0,

  drawOrder = function(self)
    return 1
  end,

  -- gets called on the next `update` frame
  init = noop,

  -- these methods will not be called until the component has been initialized
  update = noop, -- optional
  draw = noop, -- optional
  final = noop, -- optional
  _update = function(self, dt)
    self._ready = true
    self:update(dt)
    local children = self._children
    if children then
      local hasChangedPosition = self.x ~= self._prevX
        or self.y ~= self._prevY
        or self.z ~= self._prevZ

      if hasChangedPosition then
        for _,child in pairs(children) do
          -- update position relative to its parent
          local dx, dy, dz =
            (self.x - child.prevParentX),
            (self.y - child.prevParentY),
            (self.z - child.prevParentZ)
          child:setPosition(child.x + dx, child.y + dy, child.z + dz)
          child.prevParentX = self.x
          child.prevParentY = self.y
          child.prevParentZ = self.z
        end

        self._prevX = self.x
        self._prevY = self.y
        self._prevZ = self.z
      end
    end
  end,
  _drawDebug = function(self)
    self.draw(self)
    local colObjects = self.collisionObjects
    love.graphics.setColor(1,1,0,0.4)
    if colObjects then
      for i=1, #colObjects do
        local c = colObjects[i]
        local x, y = c:getPositionWithOffset()
        love.graphics.rectangle(
          'fill',
          x, y,
          c.w, c.h
        )
        love.graphics.rectangle(
          'line',
          x, y,
          c.w, c.h
        )
      end
    end
    love.graphics.setColor(0,1,0,0.2)
    love.graphics.circle(
      'fill',
      self.x,
      self.y,
      2
    )
  end,
  isComponent = true,
}

--[[
  x[NUMBER]
  y[NUMBER]
  initialProps[table] - a key/value hash of properties
]]

local uniqueIds = {}

local entityMt = {
  __index = function(t, k)
    local firstVal = t.initialProps[k]
    if firstVal ~= nil then
      return firstVal
    end
    return t.blueprint[k]
  end
}

return function(M)
  local allComponentsById = M.allComponentsById

  return function(blueprint)
    if blueprint.id then
      local isUniqueId = not uniqueIds[blueprint.id]
      assert(
        isUniqueId,
        'Duplicate id '..blueprint.id..'. Fixed ids must be unique amongst all factories'
      )
      -- add id to list of unique ids
      uniqueIds[blueprint.id] = true
    end

    function blueprint.create(props)
      props = props or objectUtils.EMPTY

      assert(type(props) == 'table', 'props must be of type `table`')
      assert(
        not props.isComponent,
        'props cannot be a component object'
      )

      local c = setProp({
        -- by keeping initial props as its own property, we can keep the input values immutable.
        initialProps = props,
        blueprint = blueprint
      }, isDevelopment)

      local componentWithDuplicateId = M.get(props.id)
      if componentWithDuplicateId then
        componentWithDuplicateId:delete(true)
      end

      local id = blueprint.id or props.id or uid()
      c._id = id
      -- add to all components list
      allComponentsById[id] = c
      setmetatable(c, entityMt)

      -- add component to default group
      if c.group then
        M.addToGroup(id, c.group, c)
      end
      c:init()
      return c
    end

    function blueprint:getPosition()
      return self.x, self.y, self.z
    end

    function blueprint:setPosition(x, y, z)
      self.x = x or self.x
      self.y = y or self.y
      self.z = z or self.z
      return self
    end

    function blueprint:setDisabled(isDisabled)
      self:setUpdateDisabled(isDisabled)
      self:setDrawDisabled(isDisabled)
      return self
    end

    function blueprint:setDrawDisabled(isDisabled)
      self._drawDisabled = isDisabled
      return self
    end

    function blueprint:setUpdateDisabled(isDisabled)
      self._updatedDisabled = isDisabled
      return self
    end

    --[[
      Sets the parent if a parent is provided, otherwise unsets it (when parent is `nil`).
      We don't want an `addChild` method so we can avoid coupling between child and parent.
    ]]
    function blueprint:setParent(parent)
      local isSameParent = parent == self.parent
      if isSameParent then
        return self
      end

      local id = self:getId()
      -- dissasociate itself from previous parent
      local previousParent = self.parent
      if (previousParent and previousParent._children) then
        previousParent._children[id] = nil
      end

      if (not parent) then
        self.parent = nil
        return self
      end

      --[[
        The child's position will now be relative to its parent,
        so we need to store the parent's initial position
      ]]
      self.prevParentX = parent.x
      self.prevParentY = parent.y
      self.prevParentZ = parent.z

      -- set new parent
      self.parent = parent
      parent._children = parent._children or {}
      -- add self as child to its parent
      parent._children[id] = self
      return self
    end

    function blueprint:delete(recursive)
      if self._deleted then
        return
      end
      M.remove(self:getId(), recursive)
      return self
    end

    function blueprint:getId()
      return self._id
    end

    function blueprint:isDeleted()
      return self._deleted
    end

    -- default methods
    for k,v in pairs(baseProps) do
      if not blueprint[k] then
        blueprint[k] = baseProps[k] or v
      end
    end

    function blueprint:addCollisionObject(group, x, y, w, h, ox, oy)
      self.collisionObjects = self.collisionObjects or {}
      local colObj = collisionObject:new(group, x, y, w, h, ox, oy)
        :setParent(self)
      table.insert(self.collisionObjects, colObj)
      return colObj
    end

    return blueprint
  end
end