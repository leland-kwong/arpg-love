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

local function toWorldCoords(obj, origin)
  local config = require 'config.config'
  return (origin.x * config.gridSize) + obj.x,
    (origin.y * config.gridSize) + obj.y
end

local aiFindTarget = require 'components.ai.find-target'.player

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
          local O = require 'utils.object-utils'
          O.assign(ai, obj.properties)

          local Color = require 'modules.color'
          local itemConfig = require 'components.item-inventory.items.config'
          return ai:set('rarityColor', Color.RARITY_LEGENDARY)
            :set('armor', ai.armor * 1.2)
            :set('moveSpeed', ai.moveSpeed * 1.5)
            :set('experience', ai.experience * 3)
        end,
        target = aiFindTarget,
        x = origin.x + (obj.x / config.gridSize),
        y = origin.y + (obj.y / config.gridSize),
        types = {
          aiType
        }
      })
    end,
  },
  ['spawn-points'] = {
    aiGroup = function(obj, grid, origin)
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
        rarity = function(ai)
          local O = require 'utils.object-utils'
          O.assign(ai, obj.properties)

          local aiRarity = require 'components.ai.rarity'
          return aiRarity(ai)
        end,
        target = aiFindTarget,
        x = origin.x + (obj.x / config.gridSize),
        y = origin.y + (obj.y / config.gridSize),
        types = spawnTypes
      })
    end,
  },
  ['environment'] = {
    triggerZone = function(obj, grid, origin)
      local Component = require 'modules.component'
      local x, y = toWorldCoords(obj, origin)
      Component.create({
        class = 'environment',
        x = x,
        y = y,
        w = obj.width,
        h = obj.height,
        name = obj.name,
        init = function(self)
          Component.addToGroup(self, 'all')
          Component.addToGroup(self, 'autoVisibility')
          Component.addToGroup(self, 'gameWorld')
          self.colObj = self:addCollisionObject('hotSpot', self.x, self.y, self.w, self.h)
            :addToWorld(collisionWorlds.map)
        end,
        update = function(self)
          if (not self.isInViewOfPlayer) then
            return
          end
          local len = select(4, self.colObj:check(self.x, self.y, function(item, other)
            local collisionGroups = require 'modules.collision-groups'
            return collisionGroups.matches(other.group, 'player') and 'slide' or false
          end))
          if len > 0 then
            Component.addToGroup(self, 'triggeredZones')
          else
            Component.removeFromGroup(self, 'triggeredZones')
          end
        end,
        serialize = function(self)
          return self.initialProps
        end
      })
    end,

    treasureChest = function(obj, grid, origin)
      local TreasureChest = require 'components.treasure-chest'
      local config = require 'config.config'
      local filePropLoader = require 'modules.dungeon.modules.file-property-loader'
      local defaultTreasure = require 'modules.dungeon.treasure-chest-definitions.default'
      local x, y = toWorldCoords(obj, origin)
      TreasureChest.create({
        lootData = filePropLoader(obj.properties.props) or defaultTreasure,
        x = x,
        y = y
      })

    end,
    environmentDoor = function(obj, grid, origin)
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
    blockOpening = function(obj, grid, origin)
      local blockOpeningParser = require 'modules.dungeon.layout-object-parsers.block-opening'
      blockOpeningParser(obj, grid, origin, cellTranslationsByLayer)
    end,
    door = function(obj, grid, origin)
      local Component = require 'modules.component'
      local Door = require 'components.door'
      local isSideView = obj.rotation == 90
      local config = require 'config.config'
      if isSideView then
        local d = Door.SideFacing.create({
          x = obj.x - config.gridSize,
          y = obj.y
        })
        Component.addToGroup(d, 'gameWorld')
      else
        local d = Door.FrontFacing.create({
          x = obj.x,
          y = obj.y
        })
        Component.addToGroup(d, 'gameWorld')
      end
    end
  },
  ['objects'] = {
    npc = function(obj, grid, origin)

    end
  },
  ['transition-points'] = {
    levelExit = function(obj, grid, origin, dungeonOptions, blockFileData)
      local Graph = require 'utils.graph'
      local universeSystem = Graph:getSystem('universe')

      local setupTransitionPoints = require 'components.hud.universe-map.setup-transition-points'
      local nodeIter = universeSystem:getAllNodes()
      local universeNodeId = nil
      for id,nodeRef in nodeIter do
        if nodeRef.level == dungeonOptions.layoutType then
          universeNodeId = id
        end
      end
      local transitionPoints = setupTransitionPoints(
        blockFileData,
        universeNodeId,
        universeSystem:getNodeLinks(universeNodeId),
        1,
        20
      )

      local msgBus = require 'components.msg-bus'
      local LevelExit = require 'components.map.level-exit'
      local config = require 'config.config'
      local Component = require 'modules.component'
      local uid = require 'utils.uid'
      local exitDefinition = transitionPoints[obj.id]
      local exitId = exitDefinition.transitionLinkId
      local toLevel = exitDefinition.layoutType
      local x, y = toWorldCoords(obj, origin)
      LevelExit.create({
        id = exitId,
        locationName = toLevel,
        x = x,
        y = y,
        onEnter = function(self)
          msgBus.send(msgBus.SCENE_STACK_REPLACE, {
            scene = require 'scene.main-scene',
            props = {
              exitId = exitId,
              location = {
                layoutType = toLevel,
                transitionPoints = transitionPoints
              }
            }
          })
        end
      })
    end,
  }
}

local function parseObjectsLayer(layerName, objectsLayer, grid, gridBlockOrigin, options, blockFileData)
  if (not objectsLayer) then
    return
  end
  local objects = objectsLayer.objects
  for i=1, #objects do
    local obj = objects[i]

    local O = require 'utils.object-utils'
    local objCopy = O.assign({}, obj, {
      -- shift positions by 1 full tile since lua indexes start at 1
      x = obj.x + blockFileData.tilewidth,
      y = obj.y + blockFileData.tileheight
    })

    local parser = objectParsersByType[layerName][obj.type]
    if parser then
      parser(objCopy, grid, gridBlockOrigin, options, blockFileData)
    end
  end
end

local function convertTileListToGrid(gridBlock)
  local groundLayer = f.find(gridBlock.layers, 'name', 'ground')
  local wallLayer = f.find(gridBlock.layers, 'name', 'walls')
  local transformFn = function(index)
    local groundValue = groundLayer.data[index]
    local wallValue = wallLayer.data[index]
    if wallValue ~= 0 then
      return cellTranslationsByLayer.walls[wallValue]
    end

    return cellTranslationsByLayer.ground[groundValue] or 'NULL_CELL'
  end

  local grid = {}
  local numCols = gridBlock.width
  local area = gridBlock.width * gridBlock.height
  for i=0, (area - 1) do
    local y = math.floor(i/numCols) + 1
    local x = (i % numCols) + 1
    grid[y] = grid[y] or {}
    grid[y][x] = transformFn((i + 1))
  end

  return grid
end

--[[
  Initializes and generates a dungeon.

  Returns a 2-d grid.
]]
local function buildDungeon(options)
  local gridBlock = require('built.maps.'..options.layoutType)

  local grid = convertTileListToGrid(gridBlock)

  local origin = {x = 0, y = 0}
  local blockData = {}
  f.forEach(
    f.filter(gridBlock.layers, function(l)
      return l.type == 'objectgroup'
    end),
    function(layer)
      parseObjectsLayer(
        layer.name,
        findLayerByName(gridBlock.layers, layer.name),
        grid,
        origin,
        options,
        gridBlock
      )
    end
  )

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
          scene = require 'scene.main-scene',
          props = {
            exitId = options.from.exitId,
            location = {
              layoutType = options.nextLevel
            }
          }
        })
      end
    })
  end

  local startPoint = f.find(
    f.find(gridBlock.layers, 'name', 'transition-points').objects,
    function(o)
      return o.type == 'checkPoint'
    end
  )
  return grid, startPoint
end

local defaultOptions = {
  layoutType = '',
  transitionPoints = {},
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

  if dungeon._built then
    return dungeon
  end

  local grid, startPoint = buildDungeon(dungeon.options)
  dungeon.grid = grid
  dungeon.startPoint = startPoint
  dungeon._built = true

  return dungeon
end

function Dungeon:remove(dungeonId)
  self.generated[dungeonId] = nil
end

function Dungeon:removeAll()
  self.generated = {}
end

return Dungeon