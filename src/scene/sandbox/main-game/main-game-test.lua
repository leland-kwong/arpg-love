local Component = require 'modules.component'
local groups = require 'components.groups'
local SceneMain = require 'scene.scene-main'
local TreasureChest = require 'components.treasure-chest'
local config = require 'config.config'
local msgBus = require 'components.msg-bus'
local GroundFlame = require 'components.particle.ground-flame'
local InventoryController = require 'components.item-inventory.controller'

local MainGameTest = {
  group = groups.firstLayer
}

local function modifyLevelRequirements()
  local base = 10
  for i=0, 1000 do
    config.levelExperienceRequirements[i + 1] = i * base
  end
end

local function insertTestItems(rootStore)
  local itemsPath = 'components.item-inventory.items.definitions'
  -- rootStore:addItemToInventory(require(itemsPath..'.pod-module-initiate').create())
  -- rootStore:addItemToInventory(require(itemsPath..'.pod-module-hammer').create())
  -- rootStore:addItemToInventory(require(itemsPath..'.pod-module-fireball').create())

  -- local generateRandomItems = require 'components.loot-generator.algorithm-1'
  -- local items = generateRandomItems(1, 10 * 100)
  -- for i=1, #items do
  --   rootStore:addItemToInventory(items[i])
  -- end
end

function MainGameTest.init(self)
  modifyLevelRequirements()

  local HomeBase = require 'scene.home-base'
  HomeBase.create():setParent(self)

  local rootStore = msgBus.send(msgBus.GAME_STATE_GET)
  InventoryController(rootStore)
  insertTestItems(rootStore)

  -- TreasureChest.create({
  --   x = 10 * config.gridSize,
  --   y = 5 * config.gridSize
  -- }):setParent(self)

  local function randomTreasurePosition()
    local mapGrid = Component.get('MAIN_SCENE').mapGrid
    local rows, cols = #mapGrid, #mapGrid[1]
    return math.random(10, cols) * config.gridSize,
      math.random(10, rows) * config.gridSize
  end

  -- local chestCount = 3
  -- for i=1, chestCount do
  --   local x, y = randomTreasurePosition()
  --   TreasureChest.create({
  --     x = x,
  --     y = y
  --   }):setParent(self)
  -- end

  local function dungeonTest(sceneRef)
    if getmetatable(sceneRef) == SceneMain then
      local dungeonTestSystem = require 'components.groups.dungeon-test'.system
      Component.addToGroup(sceneRef, dungeonTestSystem)
    end
  end
  msgBus.on(msgBus.SCENE_STACK_PUSH, dungeonTest, 2)
  msgBus.on(msgBus.SCENE_STACK_REPLACE, dungeonTest, 2)
end

return Component.createFactory(MainGameTest)

