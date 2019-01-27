local Component = require 'modules.component'
local Gui = require 'components.gui.gui'
local Position = require 'utils.position'
local Vec2 = require 'modules.brinevector'
local Grid = require 'utils.grid'
local bump = require 'modules.bump'
local msgBus = require 'components.msg-bus'

local gridSize = 32
local colWorld = bump.newWorld(gridSize)

local function renderMousePosition(self)
  love.graphics.setColor(0,0.5,1)
  local mgp = self.state.mousePosition
  love.graphics.rectangle('line', mgp.x, mgp.y, gridSize, gridSize)
end

local function renderObjects(self)
  love.graphics.setColor(1,1,0)

  local activeObjects = {}
  local collisions = self.collisions
  for i=1, #collisions do
    local c = collisions[i]
    activeObjects[c.other.id] = true
  end

  Grid.forEach(self.state.objects, function(v, x, y)
    local screenX, screenY = x * gridSize, y * gridSize
    love.graphics.setColor(0.4,0.4,0.4)
    love.graphics.rectangle('fill', screenX, screenY, gridSize, gridSize)
    if activeObjects[v.id] then
      love.graphics.setLineWidth(2)
      love.graphics.setColor(1,0,1)
      love.graphics.rectangle('line', screenX, screenY, gridSize, gridSize)
    end
  end)
end

Component.create({
  id = 'LayoutEditor',
  group = 'gui',

  init = function(self)
    local mouseCollision = {}
    colWorld:add(mouseCollision, 0, 0, gridSize, gridSize)

    Gui.create({
      x = 0,
      y = 0,
      inputContext = 'editorBase',
      scale = 1,
      onCreate = function(self)
        self.state = {
          mousePosition = Vec2(0, 0),
          mouseGridPosition = Vec2(0, 0),
          objects = {},
        }
        self.collisions = {}
      end,
      onPointerMove = function(self, ev)
        local gridX, gridY = Position.pixelsToGridUnits(ev.x, ev.y, gridSize)
        local posX, posY = gridX * gridSize, gridY * gridSize
        self.state.mousePosition = Vec2(posX, posY)
        self.state.mouseGridPosition = Vec2(gridX, gridY)

        local _, _, cols, len = colWorld:move(mouseCollision, posX, posY, function()
          return 'cross'
        end)
        self.collisions = cols

        msgBus.send('CURSOR_SET', { type = 'default' })
      end,
      onClick = function(self)
        local obj = {
          id = Component.newId(),
          connections = {}
        }
        Grid.set(self.state.objects, self.state.mouseGridPosition.x, self.state.mouseGridPosition.y, obj)
        colWorld:add(obj, self.state.mousePosition.x, self.state.mousePosition.y, gridSize, gridSize)
      end,
      onUpdate = function(self)
        self.w, self.h = love.graphics.getWidth(),
          love.graphics.getHeight()
      end,
      render = function(self)
        love.graphics.push()
        love.graphics.origin()

        renderMousePosition(self)
        renderObjects(self)

        love.graphics.pop()
      end
    }):setParent(self)
  end
})