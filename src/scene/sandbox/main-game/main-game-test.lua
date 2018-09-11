local Component = require 'modules.component'
local groups = require 'components.groups'
local SceneMain = require 'scene.scene-main'
local TreasureChest = require 'components.treasure-chest'
local config = require 'config.config'
local msgBus = require 'components.msg-bus'

local MainGameTest = {
  group = groups.all
}

local function modifyLevelRequirements()
  local base = 10
  for i=0, 1000 do
    config.levelExperienceRequirements[i + 1] = i * base
  end
end

local function insertTestItems(rootStore)
  local itemsPath = 'components.item-inventory.items.definitions'
  rootStore:addItemToInventory(require(itemsPath..'.pod-module-fireball').create(), {3, 2})
  rootStore:addItemToInventory(
    require(itemsPath..'.mock-armor').create()
    , {2, 3})
  rootStore:addItemToInventory(
    require(itemsPath..'.pod-module-slow-time').create()
  )

  local defaultBoots = require'components.item-inventory.items.definitions.mock-shoes'
  local canEquip, errorMsg = rootStore:equipItem(defaultBoots.create(), 1, 4)
  if not canEquip then
    error(errorMsg)
  end

  local defaultWeapon2 = require'components.item-inventory.items.definitions.lightning-rod'
  local canEquip, errorMsg = rootStore:equipItem(defaultWeapon2.create(), 1, 2)
  if not canEquip then
    error(errorMsg)
  end

  msgBus.send(msgBus.EQUIPMENT_CHANGE)
end

function MainGameTest.init(self)
  modifyLevelRequirements()

  local scene = SceneMain.create({
    autoSave = false
  }):setParent(self)
  insertTestItems(scene.rootStore)

  TreasureChest.create({
    x = 5 * 16,
    y = 5 * 16
  }):setParent(self)
  TreasureChest.create({
    x = 8 * 16,
    y = 5 * 16
  }):setParent(self)
  TreasureChest.create({
    x = 11 * 16,
    y = 5 * 16
  }):setParent(self)

  local function randomTreasurePosition()
    return math.random(10 * 30) * config.gridSize
  end
  TreasureChest.create({
    x = randomTreasurePosition(),
    y = randomTreasurePosition()
  }):setParent(self)

  TreasureChest.create({
    x = randomTreasurePosition(),
    y = randomTreasurePosition()
  }):setParent(self)
end

return Component.createFactory(MainGameTest)

