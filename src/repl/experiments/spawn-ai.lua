local dynamicLoad = require 'utils.dynamic-require'
local msgBus = require 'components.msg-bus'
local Component = require 'modules.component'
local inputContext = require 'modules.input-context'
local bump = require 'modules.bump'
local config = require 'config.config'
local Grid = require 'utils.grid'
local f = require 'utils.functional'
local inspect = require 'utils.inspect'

local scale = 3
local gridSize = config.gridSize * scale
local grid = {
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, },
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, }
}

-- positions items neatly using bin-packing algorithm
local function getItemPositions(items)
  local binPack = require 'utils.bin-pack'
  local done = false
  local sizeIncrement = 16
  local width, height = 0, 0
  local tryCount = 0
  local newItems
  while (not done) do
    width, height = (tryCount + 1) * sizeIncrement,
      (tryCount + 1) * sizeIncrement
    newItems = {}
    local bp = binPack(width, height)
    local i = 1
    local tooSmall = false
    while (i <= #items) and (not tooSmall) do
      local item = items[i]
      local rect = bp:insert(item.w, item.h)
      if (not rect) then
        tooSmall = true
      else
        table.insert(newItems, rect)
      end
      i = i + 1
    end
    done = (not tooSmall)
    tryCount = tryCount + 1
  end

  return width, height, newItems
end

Component.create({
  id = 'spawn-test',
  init = function(self)
    -- Component.addToGroup(self, 'gui')

    self.items = {}
    self.boundingBox = {
      x = 0,
      y = 0,
      width = 0,
      height = 0
    }
    self.state = {
      spawnPosition = {
        x = 0,
        y = 0
      }
    }

    self.listeners = {
      msgBus.on(msgBus.MOUSE_DRAG, function(ev)
        local mx, my = ev.x, ev.y

        self.mx, self.my = mx, my
        local sp = self.state.spawnPosition
        sp.x, sp.y = mx, my

        local makeItem = function(width, height, gridSize)
          return { w = width * gridSize, h = height * gridSize }
        end
        local items = {
          makeItem(1, 1, gridSize),
          makeItem(1.5, 1, gridSize),
          makeItem(1.5, 1, gridSize),
          makeItem(1, 2, gridSize),
          makeItem(1, 1, gridSize),
          makeItem(1, 1, gridSize)
        }

        local width, height, items = getItemPositions(items)
        self.items = items
        self.boundingBox.width, self.boundingBox.height = width, height

        local world = bump.newWorld(16)
        local numItems = 4

        -- setup wall collisions
        Grid.forEach(grid, function(v, x, y)
          if v == 0 then
            world:add({}, x * gridSize, y * gridSize, gridSize, gridSize)
          end
        end)

        local boundingBox = {}
        world:add(boundingBox, mx, my, width, height)
        local actualX, actualY = world:move(boundingBox, mx, my)
        self.boundingBox.x, self.boundingBox.y = actualX, actualY
      end)
    }
  end,

  update = function(self, dt)
    local msgBusMainMenu = require 'components.msg-bus-main-menu'
    msgBusMainMenu.send(msgBusMainMenu.TOGGLE_MAIN_MENU, false)
  end,

  draw = function(self)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.clear()

    local function drawWalls(v, x, y)
      if v == 0 then
        love.graphics.setColor(0,1,1)
        love.graphics.rectangle('line', x * gridSize, y * gridSize, gridSize, gridSize)
      end
    end
    Grid.forEach(grid, drawWalls)

    local sp = self.state.spawnPosition
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle(
      'line',
      self.boundingBox.x,
      self.boundingBox.y,
      self.boundingBox.width,
      self.boundingBox.height
    )

    f.forEach(self.items, function(item)
      love.graphics.setColor(1,1,0,1)
      love.graphics.rectangle(
        'line',
        item.x + self.boundingBox.x,
        item.y + self.boundingBox.y,
        item.w,
        item.h
      )
    end)

    if self.mx then
      love.graphics.setColor(1,0,0)
      love.graphics.circle('fill', self.mx, self.my, 4)
    end

    love.graphics.pop()
  end,

  drawOrder = function(self)
    return math.pow(10, 10)
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})