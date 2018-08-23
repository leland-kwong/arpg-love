local Component = require 'modules.component'
local groups = require 'components.groups'
local SceneMain = require 'scene.scene-main'
local TreasureChest = require 'components.treasure-chest'
local config = require 'config'

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
  local item1 = require(itemsPath..'.poison-blade').create()
  local item2 = require(itemsPath..'.mock-shoes').create()
  rootStore:addItemToInventory(item1, {3, 1})
  rootStore:addItemToInventory(require(itemsPath..'.poison-blade').create(), {3, 2})
  rootStore:addItemToInventory(item2, {4, 1})
  rootStore:addItemToInventory(
    require(itemsPath..'.mock-armor').create()
    , {5, 1})
  rootStore:addItemToInventory(
    require(itemsPath..'.gpow-armor').create()
    , {5, 2})
  rootStore:addItemToInventory(
    require(itemsPath..'.potion-health').create(),
    {1, 1})
  rootStore:addItemToInventory(
    require(itemsPath..'.potion-health').create(),
    {2, 1})
  rootStore:addItemToInventory(
    require(itemsPath..'.ion-generator').create()
  )
  rootStore:addItemToInventory(
    require(itemsPath..'.ion-generator-2').create()
  )
end

function MainGameTest.init(self)
  modifyLevelRequirements()

  local scene = SceneMain.create():setParent(self)
  insertTestItems(scene.rootStore)

  TreasureChest.create({
    x = 5 * 16,
    y = 5 * 16
  }):setParent(self)

  TreasureChest.create({
    x = 10 * 16,
    y = 6 * 16
  }):setParent(self)

  TreasureChest.create({
    x = 15 * 16,
    y = 6 * 16
  }):setParent(self)
end

return Component.createFactory(MainGameTest)

