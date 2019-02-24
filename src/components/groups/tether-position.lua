local Component = require 'modules.component'
local msgBus = require 'components.msg-bus'

Component.create({
  id = 'TetherPositionSystem',
  init = function(self)
    self.listeners = {
      msgBus.on('UPDATE_END', function()
        local components = Component.groups.tetherPosition.getAll()

        local tetherParentsToUpdate = {}

        for _,child in pairs(components) do
          local tp = child._tetherParent
          if (not tp) then
            Component.removeFromGroup('tetherPosition', child)
          else
            local tpx,tpy,tpz = tp.x, tp.y, tp.z
            local hasChangedPosition = tpx ~= tp._prevX
              or tpy ~= tp._prevY
              or tpz ~= tp._prevZ
              or (not child.prevParentX)

            if hasChangedPosition then
              table.insert(tetherParentsToUpdate, tp)

              -- update position relative to its parent
              local dx, dy, dz =
                (tpx - (child.prevParentX or tpx)),
                (tpy - (child.prevParentY or tpy)),
                (tpz - (child.prevParentZ or tpz))
              child:setPosition(child.x + dx, child.y + dy, child.z + dz)
              child.prevParentX = tpx
              child.prevParentY = tpy
              child.prevParentZ = tpz
            end
          end
        end

        for i=1, #tetherParentsToUpdate do
          local tp = tetherParentsToUpdate[i]
          tp._prevX = tp.x
          tp._prevY = tp.y
          tp._prevZ = tp.z
        end
      end)
    }
  end,
  final = function(self)
    msgBus.off(self.listeners)
  end
})

local function tetherPosition(child, parent)
  child._tetherParent = parent
  Component.addToGroup(child, 'tetherPosition')

  for _,c in pairs(Component.getChildren(child)) do
    tetherPosition(c, parent)
  end
end

return tetherPosition