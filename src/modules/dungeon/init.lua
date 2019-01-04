--[[
  Generates a dungeon from [Tiled](https://www.mapeditor.org/) layouts.
]]
local iterateGrid = require 'utils.iterate-grid'
local f = require 'utils.functional'
local collisionWorlds = require 'components.collision-worlds'

local Dungeon = {
  generated = {},
  isEmptyTile = require 'modules.dungeon.modules.is-empty-tile'
}

local function readTiledFileProperty(path)
  local absolutePath = string.gsub()
end

local WALL_TILE = {
  crossSection = 'floor-cross-section-0',
  walkable = false
}

local cellTranslationsByLayer = {
  walls = {
    [12] = WALL_TILE
  },
  ground = {
    [1] = {
      crossSection = 'floor-cross-section-0',
      walkable = true
    }
  }
}

local function findLayerByName(layers, name)
  for i=1, #layers do
    if layers[i].name == name then
      return layers[i]
    end
  end
end

local objectParsersByType = {
  ['unique-enemies'] = {
    legendaryEnemy = function(obj, grid, origin)
      local config = require 'config.config'
      local Map = require 'modules.map-generator.index'
      local SpawnerAi = require 'components.spawn.spawn-ai'
      local aiType = require('components.ai.types.ai-'..obj.name)
      local Component = require 'modules.component'
      SpawnerAi({
        grid = grid,
        WALKABLE = Map.WALKABLE,
        rarity = function(ai)
          local Color = require 'modules.color'
          local itemConfig = require 'components.item-inventory.items.config'
          return ai:set('rarityColor', Color.RARITY_LEGENDARY)
            :set('armor', ai.armor * 1.2)
            :set('moveSpeed', ai.moveSpeed * 1.5)
            :set('experience', 10)
        end,
        target = function()
          return Component.get('PLAYER')
        end,
        x = origin.x + (obj.x / config.gridSize),
        y = origin.y + (obj.y / config.gridSize),
        types = {
          aiType
        }
      })
    end,
  },
  ['spawn-points'] = {
    aiGroup = function(obj, grid, origin, blockData)
      local config = require 'config.config'
      local Map = require 'modules.map-generator.index'
      local SpawnerAi = require 'components.spawn.spawn-ai'
      local Component = require 'modules.component'

      local aiTypes = require 'components.ai.types'
      local chance = require 'utils.chance'
      local AiTypeGen = chance(f.map(f.keys(aiTypes.types), function(k)
        return {
          chance = 1,
          __call = function()
            return aiTypes.types[k]
          end
        }
      end))
      local spawnTypes = {}
      for i=1, obj.properties.groupSize do
        table.insert(spawnTypes, AiTypeGen())
      end

      SpawnerAi({
        grid = grid,
        WALKABLE = Map.WALKABLE,
        target = function()
          return Component.get('PLAYER')
        end,
        x = origin.x + (obj.x / config.gridSize),
        y = origin.y + (obj.y / config.gridSize),
        types = spawnTypes
      })
    end,
  },
  ['environment'] = {
    treasureChest = function(obj, grid, origin, blockData)
      local TreasureChest = require 'components.treasure-chest'
      local config = require 'config.config'
      local filePropLoader = require 'modules.dungeon.modules.file-property-loader'
      local O = require 'utils.object-utils'
      TreasureChest.create(O.extend({
        x = (origin.x * config.gridSize) + obj.x,
        y = (origin.y * config.gridSize) + obj.y
      }, filePropLoader(obj.properties.props)))
    end,
    environmentDoor = function(obj, grid, origin, blockData)
      local config = require 'config.config'
      local Component = require 'modules.component'
      local AnimationFactory = require 'components.animation-factory'
      local doorGridWidth, doorGridHeight = obj.width / config.gridSize, obj.height / config.gridSize

      local blockOpeningParser = require 'modules.dungeon.layout-object-parsers.block-opening'
      blockOpeningParser(obj, grid, origin, blockData, cellTranslationsByLayer)

      for x=1, doorGridWidth do
        for y=1, doorGridHeight do
          local door = Component.create({
            class = 'environment',
            x = (origin.x * config.gridSize) + obj.x + ((x - 1) * config.gridSize),
            y = (origin.y * config.gridSize) + obj.y + ((y - 1) * config.gridSize),
            init = function(self)
              Component.addToGroup(self, 'bossDoors')
              Component.addToGroup(self, 'gameWorld')
              Component.addToGroup(self, 'mapStateSerializers')
            end,
            enable = function(self)
              local collisionWorlds = require 'components.collision-worlds'
              self.collisionObject = self:addCollisionObject(
                'obstacle',
                self.x,
                self.y,
                config.gridSize,
                config.gridSize
              ):addToWorld(collisionWorlds.map)
              Component.addToGroup(self, 'all')
            end,
            disable = function(self)
              if self.collisionObject then
                self.collisionObject:delete()
              end
              self.collisionObject = nil
              Component.removeFromGroup(self, 'all')
            end,
            update = function(self)
              local Map = require 'modules.map-generator.index'
              local mapGrid = Component.get('MAIN_SCENE').mapGrid
              local Grid = require 'utils.grid'
              local isTraversable = Map.WALKABLE(
                Grid.get(mapGrid, self.x / config.gridSize, self.y / config.gridSize)
              )
              self:setDrawDisabled(not isTraversable)
            end,
            draw = function(self)
              local animation = AnimationFactory:newStaticSprite('environment-door')
              local ox, oy = animation:getOffset()
              love.graphics.setColor(1,1,1)
              love.graphics.draw(
                AnimationFactory.atlas,
                animation.sprite,
                self.x,
                self.y,
                0,
                1,
                1,
                ox,
                oy
              )
            end,
            drawOrder = function(self)
              return Component.groups.all:drawOrder(self)
            end,
            serialize = function(self)
              return self.initialProps
            end
          })
        end
      end
    end,
    levelExit = function(obj, grid, origin, blockData)
      local msgBus = require 'components.msg-bus'
      local LevelExit = require 'components.map.level-exit'
      local config = require 'config.config'
      local Component = require 'modules.component'
      local uid = require 'utils.uid'
      local exitId = 'exit-'..uid()
      local nextLevel = obj.properties.location or blockData.nextLevel
      local mapId = Dungeon:new({
        layoutType = nextLevel,
        from = {
          mapId = Component.get('MAIN_SCENE').mapId,
          exitId = exitId,
        },
        nextLevel = blockData.layoutType
      })
      LevelExit.create({
        id = exitId,
        locationName = nextLevel,
        x = origin.x * config.gridSize + obj.x,
        y = origin.y * config.gridSize + obj.y,
        onEnter = function(self)
          msgBus.send(msgBus.SCENE_STACK_PUSH, {
            scene = require 'scene.scene-main',
            props = {
              mapId = mapId
            }
          })
        end
      })
    end,
    ramp = function(obj, grid, origin, blockData)
      local Grid = require 'utils.grid'
      local Math = require 'utils.math'
      local config = require 'config.config'
      local Position = require 'utils.position'
      local gridX, gridY = Position.pixelsToGridUnits(obj.x, obj.y, config.gridSize)
      local bLine = require 'utils.bresenham-line'
      local coords = obj.polygon
      local x1, y1 = Position.pixelsToGridUnits(coords[1].x, coords[1].y, config.gridSize)
      local x2, y2 = Position.pixelsToGridUnits(coords[2].x, coords[2].y, config.gridSize)
      local gridHeight, gridWidth = math.abs(coords[1].y - coords[4].y) / config.gridSize
      local slope = coords[2].y/coords[2].x
      local slope2 = (coords[3].y - coords[4].y) / (coords[3].x - coords[4].x)

      -- make sure shape is parallelogram
      assert(slope == slope2, 'ramp shape must be a parallelogram')
      assert(coords[1].x == 0 and coords[1].x == 0, 'origin point coordinates must be [0,0]')

      -- setup subGrid for bitmask tiling
      local subGrid = {}

      for row=1, gridHeight do
        bLine(
          x1, y1,
          x2, y2,
          function(_, x, y, length)
            local rowOffset = row - 1

            local offsetY = Math.round(-slope * (length - 1) * config.gridSize)
            local cellData = {
              type = 'RAMP',
              slope = slope,
              x = obj.x + ((origin.x + x) * config.gridSize),
              y = obj.y + ((origin.y + rowOffset) * config.gridSize) - offsetY,
              walkable = true
            }

            local actualX, actualY = (origin.x + x) * config.gridSize + obj.x,
              (origin.y + y + rowOffset) * config.gridSize + obj.y
            local gridX, gridY = actualX/config.gridSize, actualY/config.gridSize
            Grid.set(grid, gridX, gridY, cellData)
            Grid.set(subGrid, gridX, row, cellData)
          end
        )
      end

      local function isRampTile(v)
        return v and v.type == 'RAMP'
      end

      local function setupStairSprites(cellData, x, y)
        local bitmaskTileValue = require 'utils.tilemap-bitmask'
        local tileValue = bitmaskTileValue(subGrid, x, y, isRampTile)
        cellData.animations = {
          'map-ramp-'..tileValue
        }

        local shouldShowShadow = slope ~= 0
        if shouldShowShadow then
          local shadowWidth = 2
          local shadowOffsetX = config.gridSize - ((slope < 0) and (shadowWidth + config.gridSize) or 0)
          local shadowOffsetY = (slope > 0) and 3 or Math.round(-slope * config.gridSize)
          cellData.shadow = {
            sprite = 'pixel-white-1x1',
            x = cellData.x + shadowOffsetX,
            y = cellData.y + shadowOffsetY,
            sx = shadowWidth,
            sy = 16,
            color = {0,0,0,0.25}
          }
        end
      end

      Grid.forEach(subGrid, setupStairSprites)
    end,
    blockOpening = function(obj, grid, origin, blockData)
      local blockOpeningParser = require 'modules.dungeon.layout-object-parsers.block-opening'
      blockOpeningParser(obj, grid, origin, blockData, cellTranslationsByLayer)
    end
  }
}

local function parseObjectsLayer(layerName, objectsLayer, grid, gridBlockOrigin, blockData, gridBlock)
  if (not objectsLayer) then
    return
  end
  local objects = objectsLayer.objects
  for i=1, #objects do
    local obj = objects[i]

    -- shift positions by 1 full tile since lua indexes start at 1
    obj.x = obj.x + gridBlock.tilewidth
    obj.y = obj.y + gridBlock.tileheight

    local parser = objectParsersByType[layerName][obj.type]
    if parser then
      parser(obj, grid, gridBlockOrigin, blockData)
    end
  end
end

local function loadGridBlock(file)
  local dynamicModule = require 'modules.dynamic-module'
  --[[
    Note: we use filesystem load instead of `require` so that we're not loading a cached instance.
    This is important because we are mutating the dataset, so we need a fresh dataset each time.
  ]]
  return dynamicModule('built/maps/'..file..'.lua')
end

local function addGridBlock(grid, gridBlockToAdd, startX, startY, transformFn, blockName)
  collisionWorlds.zones:add(
    {name = blockName},
    startX,
    startY,
    gridBlockToAdd.width,
    gridBlockToAdd.height
  )
  local numCols = gridBlockToAdd.width
  local area = gridBlockToAdd.width * gridBlockToAdd.height
  for i=0, (area - 1) do
    local y = math.floor(i/numCols) + 1
    local x = (i % numCols) + 1
    -- local coordinates
    local actualX = startX + x
    local actualY = startY + y
    grid[actualY] = grid[actualY] or {}
    grid[actualY][actualX] = transformFn((i + 1), x, y)
  end
  return grid
end

--[[
  Initializes and generates a dungeon.

  Returns a 2-d grid.
]]
local function buildDungeon(options)
  local layoutGenerator = require('modules.dungeon.layouts.'..options.layoutType)
  local layout = layoutGenerator()
  local extractProps = require 'utils.object-utils.extract'
  local gridBlockNames, columns, exitPosition = extractProps(layout, 'gridBlockNames', 'columns', 'exitPosition')

  collisionWorlds.reset(collisionWorlds.zones)

  local grid = {}
  local numBlocks = #gridBlockNames
  local numCols = columns
  local numRows = numBlocks/numCols
  local layerProcessingQueue = {}
  for blockIndex=0, (numBlocks - 1) do
    local gridBlockName = gridBlockNames[blockIndex + 1]
    local gridBlock = loadGridBlock(gridBlockName)

    -- block-level coordinates
    local blockX = (blockIndex % numCols)
    local blockY = math.floor(blockIndex/numCols)
    local blockWidth, blockHeight = gridBlock.width, gridBlock.height

    local overlapAdjustment = 0 --[[
      the number of cells to overlap between blocks. This is mostly used as an option for making the layout share walls between blocks
    ]]
    local overlapAdjustmentX, overlapAdjustmentY = (overlapAdjustment * blockX), (overlapAdjustment * blockY)
    -- grid units
    local origin = {
      x = (blockX * blockWidth),
      y = (blockY * blockHeight)
    }
    if origin.x > 0 then
      origin.x = origin.x + overlapAdjustmentX
    end
    if origin.y > 0 then
      origin.y = origin.y + overlapAdjustmentY
    end
    local blockData = options
    addGridBlock(
      grid,
      gridBlock,
      origin.x,
      origin.y,
      function(index, localX, localY)
        local groundLayer = findLayerByName(gridBlock.layers, 'ground')
        local groundValue = groundLayer.data[index]
        local wallLayer = findLayerByName(gridBlock.layers, 'walls')
        local wallValue = wallLayer.data[index]
        if wallValue ~= 0 then
          return cellTranslationsByLayer.walls[wallValue]
        end

        return cellTranslationsByLayer.ground[groundValue] or 'NULL_CELL'
      end,
      gridBlockName
    )
    local layersToParse = {
      'spawn-points',
      'unique-enemies',
      'environment'
    }
    table.insert(layerProcessingQueue, function()
      f.forEach(layersToParse, function(layerName)
        parseObjectsLayer(
          layerName,
          findLayerByName(gridBlock.layers, layerName),
          grid,
          origin,
          blockData,
          gridBlock
        )
      end)
    end)
  end

  for _,fn in ipairs(layerProcessingQueue) do
    fn()
  end

  local connectsToAnotherMap = options.from.mapId
  -- create an exit that points back to the previous map
  if connectsToAnotherMap then
    local LevelExit = require 'components.map.level-exit'
    local config = require 'config.config'
    LevelExit.create({
      x = exitPosition.x * config.gridSize,
      y = exitPosition.y * config.gridSize,
      locationName = options.nextLevel,
      onEnter = function()
        local msgBus = require 'components.msg-bus'
        msgBus.send(msgBus.SCENE_STACK_PUSH, {
          scene = require 'scene.scene-main',
          props = {
            mapId = options.from.mapId,
            exitId = options.from.exitId
          }
        })
      end
    })
  end

  return grid
end

local defaultOptions = {
  layoutType = '',
  -- previous map
  from = {
    mapId = nil,
    exitId = nil
  },
  nextLevel = '' -- the next layout that the exit should use
}

local function validateOptions(options)
  for k,v in pairs(options or {}) do
    if defaultOptions[k] == nil then
      error('invalid dungeon option `'..k..'`')
    end
  end
end

-- generates a dungeon and returns the dungeon id
function Dungeon:new(options)
  assert(type(options) == 'table')
  assert(type(options.layoutType) == 'string', 'layout type should be the name of the layout file')
  validateOptions(options)
  -- assign defaults after validating first
  local assign = require 'utils.object-utils'.assign
  options = assign({}, defaultOptions, options)

  local uid = require 'utils.uid'
  local dungeonId = uid()
  self.generated[dungeonId] = {
    options = options
  }
  return dungeonId
end

-- gets the data for the generated dungeon by its id
function Dungeon:getData(dungeonId)
  local dungeon = self.generated[dungeonId]
  if (not dungeon) then
    return nil
  end
  dungeon.grid = dungeon.grid or buildDungeon(dungeon.options)
  return dungeon
end

function Dungeon:remove(dungeonId)
  self.generated[dungeonId] = nil
end

function Dungeon:removeAll()
  self.generated = {}
end

return Dungeon