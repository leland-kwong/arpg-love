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

  -- local function dungeonTest(sceneRef)
  --   if getmetatable(sceneRef) == SceneMain then
  --     Component.addToGroup(sceneRef, 'dungeonTest')
  --     return msgBus.CLEANUP
  --   end
  -- end
  -- msgBus.on(msgBus.SCENE_STACK_PUSH, dungeonTest, 11)
end

return Component.createFactory(MainGameTest)

