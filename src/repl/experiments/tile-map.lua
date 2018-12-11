local dynamicLoad = function(pkg)
  if package.loaded[pkg] then
    package.loaded[pkg] = nil
  end
  return require(pkg)
end

local tileBitmasking = dynamicLoad 'utils.tilemap-bitmask'
local Grid = dynamicLoad 'utils.grid'
local Camera = dynamicLoad 'modules.camera'
local msgBus = require 'components.msg-bus'

local json = dynamicLoad 'lua_modules.json'
local Animation = dynamicLoad 'modules.animation'

local lastModifiedCache = {}
local function hasFileChanged(path)
  local lastModified = lastModifiedCache[path]
  local info = love.filesystem.getInfo(path)
  local newModTime = info and info.modtime
  lastModifiedCache[path] = newModTime
  return newModTime and (lastModified ~= newModTime)
end

local lastModified = {}
local spriteAtlas, spriteData
local function hasChanged(path)
  local info = love.filesystem.getInfo(path)
  if info and info.modtime then
    local hasChanged = lastModified[path] ~= info.modtime
    lastModified[path] = info.modtime
    return hasChanged
  end
  return false
end
local checkCount = 0
local createAnimationFactory = function()
  local paths = {
    spriteSheet = 'built/sprite.png',
    spriteData = 'built/sprite.json'
  }
  if (checkCount % 30 == 0) and hasChanged(paths.spriteData) then
    local ok = pcall(function()
      spriteAtlas = love.graphics.newImage(paths.spriteSheet)
      spriteData = json.decode(
        love.filesystem.read(paths.spriteData)
      )
      Animation = dynamicLoad 'modules.animation'
    end)
    if ok then
      print('sprite sheet reloaded')
    end
  end
  checkCount = checkCount + 1
  return Animation(spriteData, spriteAtlas, 2)
end
local AnimationFactory = createAnimationFactory

local grid = {
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 1, 0,},
  {0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0,},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
  {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,},
}

state = state or {
  scale = 2,
  translate = {
    x = 0,
    y = 0,
    dragStartX = 0,
    dragStartY = 0
  }
}

local camera = Camera()

local newGrid = {}
tileBitmasking.iterateGrid(grid, function(v, x, y)
  Grid.set(newGrid, x, y, v)
end, 0)

local function drawScreenCenter()
  love.graphics.push()
  love.graphics.origin()
  local x, y = love.graphics.getDimensions()
  x, y = x/2, y/2

  local crosshairSize = 10
  love.graphics.setColor(1,1,1)
  local oLineWidth = love.graphics.getLineWidth()
  love.graphics.setLineWidth(2)
  love.graphics.line(
    x - crosshairSize/2,
    y,
    x + crosshairSize/2,
    y
  )
  love.graphics.line(
    x,
    y - crosshairSize/2,
    x,
    y + crosshairSize/2
  )
  love.graphics.setLineWidth(oLineWidth)
  love.graphics.pop()
end

local Component = require 'modules.component'
Component.create({
  id = 'tile-map-test',
  init = function(self)
    Component.addToGroup(self, 'gui')

    local InputContext = dynamicLoad 'modules.input-context'
    InputContext.set('Tilemap-test')

    self.listeners = {
      msgBus.on(msgBus.MOUSE_WHEEL_MOVED, function(ev)
        local Math = require 'utils.math'
        local dy = ev[2]
        state.scale = Math.clamp(state.scale + dy, 1, 10)
      end),

      msgBus.on(msgBus.MOUSE_DRAG_START, function(ev)
        local tx = state.translate
        tx.dragStartX, tx.dragStartY = tx.x, tx.y
      end),

      msgBus.on(msgBus.MOUSE_DRAG, function(ev)
        local tx = state.translate
        tx.x, tx.y = tx.dragStartX - (ev.dx / camera.scale), tx.dragStartY - (ev.dy / camera.scale)
      end)
    }
  end,

  update = function(self, dt)
    local tx = state.translate
    camera
      :setScale(state.scale, 0.25)
      :setPosition(tx.x, tx.y)
      :update(dt)
  end,

  draw = function(self)
    local af = AnimationFactory()
    camera:attach()
    love.graphics.clear(0,0,0)

    local gridSize = 16

    love.graphics.setColor(1,1,1)
    Grid.forEach(grid, function(v, x, y)
      local tile = AnimationFactory():newStaticSprite('floor-1')
      tile:draw(
        (x - 1) * gridSize,
        (y - 1) * gridSize
      )
    end)

    local function drawBase(v, x, y)
      local actualX, actualY = (x - 1) * gridSize, (y) * gridSize
      local tileCapDefault = af:newStaticSprite('map-0')
      local ox, oy = tileCapDefault:getSourceOffset()
      local oBlendMode = love.graphics.getBlendMode()
      love.graphics.setColor(0,0,0,0.3)
      tileCapDefault:draw(actualX, actualY + 16, 0, 1, 1, ox, oy)
      love.graphics.setBlendMode(oBlendMode)

      local tileBase = af:newStaticSprite('map-base-'..v)
      local ox, oy = tileBase:getSourceOffset()
      love.graphics.setColor(1,1,1,1)
      tileBase:draw(actualX, actualY, 0, 1, 1, ox, oy)
    end
    Grid.forEach(newGrid, drawBase)

    local function drawTileCap(v, x, y)
      local actualX, actualY = (x - 1) * gridSize, (y) * gridSize
      love.graphics.setColor(1,1,1)
      local tileCap = af:newStaticSprite('map-'..v)
      local height = tileCap:getHeight()
      local ox, oy = tileCap:getSourceOffset()
      tileCap:draw(actualX, actualY - 16, 0, 1, 1, ox, oy)
    end
    Grid.forEach(newGrid, drawTileCap)

    camera:detach()
    drawScreenCenter()
  end,

  drawOrder = function()
    return math.pow(10, 10)
  end,

  final = function(self)
    msgBus.off(self.listeners)
  end
})