local Component = require 'modules.component'
local groups = require 'components.groups'
local SceneMain = require 'scene.scene-main'
local TreasureChest = require 'components.treasure-chest'
local config = require 'config.config'
local msgBus = require 'components.msg-bus'
local GroundFlame = require 'components.particle.ground-flame'

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
  rootStore:addItemToInventory(require(itemsPath..'.pod-module-initiate').create())
  rootStore:addItemToInventory(require(itemsPath..'.pod-module-hammer').create())
  rootStore:addItemToInventory(require(itemsPath..'.pod-module-fireball').create())

  local generateRandomItem = require 'components.loot-generator.algorithm-1'
  for i=1, 10 do
    rootStore:addItemToInventory(
      generateRandomItem()
    )
  end
end

function MainGameTest.init(self)
  modifyLevelRequirements()

  local scene = SceneMain.create({
    autoSave = false
  }):setParent(self)
  insertTestItems(scene.rootStore)

  TreasureChest.create({
    x = 10 * config.gridSize,
    y = 5 * config.gridSize
  }):setParent(self)

  local function randomTreasurePosition()
    local mapGrid = Component.get('MAIN_SCENE').mapGrid
    local rows, cols = #mapGrid, #mapGrid[1]
    return math.random(10, 20) * config.gridSize,
      math.random(40, rows - 2) * config.gridSize
  end

  local chestCount = 3
  for i=1, chestCount do
    local x, y = randomTreasurePosition()
    TreasureChest.create({
      x = x,
      y = y
    }):setParent(self)
  end
end

return Component.createFactory(MainGameTest)

