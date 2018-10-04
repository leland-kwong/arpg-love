local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local ParticleFx = require 'components.particle.particle'
local config = require 'config.config'
local animationFactory = require 'components.animation-factory'
local collisionWorlds = require 'components.collision-worlds'
local collisionObject = require 'modules.collision'
local camera = require 'components.camera'
local Position = require 'utils.position'
local Map = require 'modules.map-generator.index'
local FlowField = require 'modules.flow-field.flow-field'
local Color = require 'modules.color'
local memoize = require 'utils.memoize'
local LineOfSight = memoize(require'modules.line-of-sight')
local Math = require 'utils.math'
local getDist = memoize(require('utils.math').dist)
local WeaponCore = require 'components.player.weapon-core'
local InventoryController = require 'components.item-inventory.controller'
local Inventory = require 'components.item-inventory.inventory'
local HealSource = require 'components.heal-source'
require'components.item-inventory.equipment-change-handler'

local colMap = collisionWorlds.map
local keyMap = config.keyboard
local mouseInputMap = config.mouseInputMap

local startPos = {
  x = config.gridSize * 3,
  y = config.gridSize * 3,
}

local frameRate = 60
local DIRECTION_RIGHT = 1
local DIRECTION_LEFT = -1

local collisionGroups = {
  obstacle = true,
  ai = true
}

local function collisionFilter(item, other)
  if not collisionGroups[other.group] then
    return false
  end
  return 'slide'
end

local function connectInventory()
  local rootState = msgBus.send(msgBus.GAME_STATE_GET)
  local inventoryController = InventoryController(rootState)

  -- add default weapons
  if rootState:get().isNewGame then
    local itemSystem = require(require('alias').path.itemSystem)

    local defaultHealthPotion = require(require('alias').path.itemDefs..'.potion-health')
    local canEquip, errorMsg = rootState:equipItem(itemSystem.create(defaultHealthPotion), 1, 5)
    if not canEquip then
      error(errorMsg)
    end

    local defaultWeapon = require'components.item-inventory.items.definitions.pod-module-initiate'
    local canEquip, errorMsg = rootState:equipItem(itemSystem.create(defaultWeapon), 1, 1)
    if not canEquip then
      error(errorMsg)
    end

    local defaultEnergyPotion = require'components.item-inventory.items.definitions.potion-energy'
    local canEquip, errorMsg = rootState:equipItem(itemSystem.create(defaultEnergyPotion), 2, 5)
    if not canEquip then
      error(errorMsg)
    end

    local defaultBoots = require'components.item-inventory.items.definitions.mock-shoes'
    local canEquip, errorMsg = rootState:equipItem(itemSystem.create(defaultBoots), 1, 4)
    if not canEquip then
      error(errorMsg)
    end

    -- local defaultWeapon2 = require'components.item-inventory.items.definitions.lightning-rod'
    -- local canEquip, errorMsg = rootState:equipItem(defaultWeapon2.create(), 1, 2)
    -- if not canEquip then
    --   error(errorMsg)
    -- end

    -- local defaultArmor = require('components.item-inventory.items.definitions.mock-armor').create()
    -- local canEquip, errorMsg = rootState:equipItem(defaultArmor, 2, 3)
    -- if not canEquip then
    --   error(errorMsg)
    -- end

    -- local defaultWeapon3 = require'components.item-inventory.items.definitions.pod-module-fireball'
    -- rootState:addItemToInventory(defaultWeapon3.create())
  end

  -- trigger equipment change for items that were previously equipped from loading the state
  msgBus.send(msgBus.EQUIPMENT_CHANGE)
end

local function connectAutoSave(parent)
  local tick = require 'utils.tick'
  local fileSystem = require 'modules.file-system'
  local lastSavedState = nil
  if (not config.autoSave) then
    return
  end

  local function saveState()
    local rootState = msgBus.send(msgBus.GAME_STATE_GET)
    rootState:set('isNewGame', false)
    local state = rootState:get()
    local hasChanged = state ~= lastSavedState
    if hasChanged then
      fileSystem.saveFile(
        rootState:getId(),
        rootState:get()
      )
      lastSavedState = state
    end
  end
  local autoSaveTimer = tick.recur(saveState, 0.5)
  Component.create({
    init = function(self)
      Component.addToGroup(self, groups.system)
    end,
    final = function()
      autoSaveTimer:stop()
    end
  }):setParent(parent)
end

local Player = {
  id = 'PLAYER',
  class = collisionGroups.player,
  group = groups.all,
  x = startPos.x,
  y = startPos.y,
  facingDirectionX = 1,
  facingDirectionY = 1,
  pickupRadius = 5 * config.gridSize,
  moveSpeed = 100,
  flowFieldDistance = 30,
  attackRecoveryTime = 0,

  -- collision properties
  h = 1,
  w = 1,
  mapGrid = nil,

  init = function(self)
    Component.addToGroup(self, groups.character)
    self.listeners = {
      msgBus.on(msgBus.PLAYER_STATS_NEW_MODIFIERS, function(msgValue)
        local newModifiers = msgValue
        msgBus.send(msgBus.GAME_STATE_GET):set('statModifiers', newModifiers)
      end),

      msgBus.on(msgBus.KEY_PRESSED, function(v)
        local key = v.key
        local rootState = msgBus.send(msgBus.GAME_STATE_GET)
        local isActive = rootState:get().activeMenu == 'INVENTORY'
        if key == config.keyboard.INVENTORY_TOGGLE then
          if not self.inventory then
            self.inventory = Inventory.create({
              rootStore = rootState,
              slots = function()
                return rootState:get().inventory
              end
            }):setParent(self.hudRoot)
            rootState:set('activeMenu', 'INVENTORY')
          else
            self.inventory:delete(true)
            self.inventory = nil
            rootState:set('activeMenu', false)
          end
        end

        if config.keyboard.PORTAL_OPEN == key then
          msgBus.send(msgBus.PORTAL_OPEN)
        end
      end),

      msgBus.on(msgBus.PLAYER_HEAL_SOURCE_ADD, function(v)
        HealSource.add(self, v, msgBus.send(msgBus.GAME_STATE_GET))
      end),

      msgBus.on(msgBus.PLAYER_HEAL_SOURCE_REMOVE, function(v)
        HealSource.remove(self, v.source)
      end),

      msgBus.on(msgBus.PLAYER_DISABLE_ABILITIES, function(msg)
        self.clickDisabled = msg
      end),

      msgBus.on(msgBus.PLAYER_LEVEL_UP, function(msg)
        local tick = require 'utils.tick'
        local fx = ParticleFx.Basic.create({
          x = self.x,
          y = self.y + 10,
          duration = 1,
          width = 4
        }):setParent(self)
      end),

      msgBus.on(msgBus.DROP_ITEM_ON_FLOOR, function(item)
        msgBus.send(
          msgBus.GENERATE_LOOT,
          {self.x, self.y, item}
        )
      end),

      msgBus.on(msgBus.ITEM_PICKUP_SUCCESS, function()
        msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, false)
      end),

      msgBus.on(msgBus.ITEM_PICKUP, function(msg)
        local item = msg
        local calcDist = require'utils.math'.dist
        local dist = calcDist(self.x, self.y, item.x, item.y)
        local outOfRange = dist > self.pickupRadius
        local gridX1, gridY1 = Position.pixelsToGridUnits(self.x, self.y, config.gridSize)
        local gridX2, gridY2 = Position.pixelsToGridUnits(item.x, item.y, config.gridSize)
        local canWalkToItem = LineOfSight(self.mapGrid, Map.WALKABLE)(gridX1, gridY1, gridX2, gridY2)
        if canWalkToItem and (not outOfRange) then
          msgBus.send(msgBus.PLAYER_DISABLE_ABILITIES, true)
          item:pickup()
        end
      end)
    }
    connectAutoSave(self)
    self.hudRoot = Component.create({
      group = groups.hud
    })
    local Hud = require 'components.hud.hud'
    Hud.create({
      player = self,
      rootStore = msgBus.send(msgBus.GAME_STATE_GET)
    }):setParent(self.hudRoot)
    connectInventory()
    self.onDamageTaken = function(self, actualDamage, actualNonCritDamage, criticalMultiplier)
      if (actualDamage > 0) then
        msgBus.send(msgBus.PLAYER_HIT_RECEIVED, actualDamage)
      end
    end
    self.getFlowField = FlowField(function (grid, x, y, dist)
      local row = grid[y]
      local cell = row and row[x]
      return
        (cell == Map.WALKABLE) and
        (dist < self.flowFieldDistance)
    end)
    self.getFlowField = require'utils.perf'({
      enabled = false,
      done = function(_, totalTime, callCount)
        consoleLog('flowfield', totalTime / callCount)
      end
    })(self.getFlowField)

    local CreateStore = require'components.state.state'
    self.rootStore = msgBus.send(msgBus.GAME_STATE_GET)
    self.dir = DIRECTION_RIGHT
    colMap:add(self, self.x, self.y, self.w, self.h)

    local energyRegenerationDuration = 99999999
    msgBus.send(msgBus.PLAYER_HEAL_SOURCE_ADD, {
      source = 'BASE_ENERGY_REGENERATION',
      amount = energyRegenerationDuration *
        self.rootStore:get().statModifiers.energyRegeneration,
      duration = energyRegenerationDuration,
      property = 'energy',
      maxProperty = 'maxEnergy'
    })

    self.animations = {
      idle = animationFactory:new({
        'character-1',
        'character-8',
        'character-9',
        'character-10',
        'character-11'
      }),
      run = animationFactory:new({
        'character-15',
        'character-16',
        'character-17',
        'character-18',
      })
    }

    -- set default animation since its needed in the draw method
    self.animation = self.animations.idle

    local collisionW, collisionH = self.animations.idle:getSourceSize()
    local collisionOffX, collisionOffY = self.animations.idle:getSourceOffset()
    self.colObj = self:addCollisionObject(
      'player',
      self.x,
      self.y,
      collisionW,
      14,
      collisionOffX,
      5
    ):addToWorld(colMap)

    WeaponCore.create({
      x = self.x,
      y = self.y
    }):setParent(self)
  end
}

local function handleMovement(self, dt)
  local totalMoveSpeed = self:getCalculatedStat('moveSpeed')

  if self.attackRecoveryTime > 0 then
    totalMoveSpeed = 0
  end

  local moveAmount = totalMoveSpeed * dt
  local origx, origy = self.x, self.y
  local mx, my = camera:getMousePosition()
  local mDx, mDy = Position.getDirection(self.x, self.y, mx, my)

  local nextX, nextY = self.x, self.y
  self.dir = mDx > 0 and DIRECTION_RIGHT or DIRECTION_LEFT

  -- MOVEMENT
  local inputX, inputY = 0, 0
  if love.keyboard.isDown(keyMap.RIGHT) then
    inputX = 1
  end

  if love.keyboard.isDown(keyMap.LEFT) then
    inputX = -1
  end

  if love.keyboard.isDown(keyMap.UP) then
    inputY = -1
  end

  if love.keyboard.isDown(keyMap.DOWN) then
    inputY = 1
  end

  local dx, dy = Position.getDirection(0, 0, inputX, inputY)
  nextX = nextX + (dx * moveAmount)
  nextY = nextY + (dy * moveAmount)

  self.facingDirectionX = mDx
  self.facingDirectionY = mDy
  self.moveDirectionX = dx
  self.moveDirectionY = dy

  return nextX, nextY, totalMoveSpeed
end

local function handleAnimation(self, dt, nextX, nextY, moveSpeed)
  local moving = self.x ~= nextX or self.y ~= nextY

  -- ANIMATION STATES
  if moving then
    self.animation = self.animations.run
      :update(moveSpeed/(moveSpeed*2.5)*dt)
  else
    self.animation = self.animations.idle
      :update(dt/12)
  end
end

local function handleAbilities(self, dt)
  -- ACTIVE_ITEM_1
  local isItem1Activate = love.keyboard.isDown(keyMap.ACTIVE_ITEM_1)
  if not self.clickDisabled and isItem1Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'ACTIVE_ITEM_1')
  end

  -- ACTIVE_ITEM_2
  local isItem2Activate = love.keyboard.isDown(keyMap.ACTIVE_ITEM_2)
  if not self.clickDisabled and isItem2Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'ACTIVE_ITEM_2')
  end

  -- only disable equipment skills since we want to allow potions to still be used
  if self.clickDisabled or self.rootStore:get().activeMenu then
    return
  end

  -- SKILL_1
  local isSkill1Activate = love.keyboard.isDown(keyMap.SKILL_1) or
    love.mouse.isDown(mouseInputMap.SKILL_1)
  if not self.clickDisabled and isSkill1Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'SKILL_1')
  end

  -- SKILL_2
  local isSkill2Activate = love.keyboard.isDown(keyMap.SKILL_2) or
    love.mouse.isDown(mouseInputMap.SKILL_2)
  if not self.clickDisabled and isSkill2Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'SKILL_2')
  end

  -- SKILL_3
  local isSkill3Activate = love.keyboard.isDown(keyMap.SKILL_3) or
    (mouseInputMap.SKILL_3 and love.mouse.isDown(mouseInputMap.SKILL_3))
  if not self.clickDisabled and isSkill3Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'SKILL_3')
  end

  -- SKILL_4
  local isSkill4Activate = love.keyboard.isDown(keyMap.SKILL_4) or
    (mouseInputMap.SKILL_4 and love.mouse.isDown(mouseInputMap.SKILL_4))
  if not self.clickDisabled and isSkill4Activate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'SKILL_4')
  end

  -- MOVE_BOOST
  local isMoveBoostActivate = love.keyboard.isDown(keyMap.MOVE_BOOST) or
    (mouseInputMap.MOVE_BOOST and love.mouse.isDown(mouseInputMap.MOVE_BOOST))
  if not self.clickDisabled and isMoveBoostActivate then
    msgBus.send(msgBus.PLAYER_USE_SKILL, 'MOVE_BOOST')
  end
end

local min = math.min

local function updateHealthAndEnergy(rootStore)
  local state = rootStore:get()
  local mods = state.statModifiers
  rootStore:set('health', min(state.health, state.maxHealth + mods.maxHealth))
  rootStore:set('energy', min(state.energy, state.maxEnergy + mods.maxEnergy))
end

function Player.update(self, dt)
  self.attackRecoveryTime = self.attackRecoveryTime - dt
  self.equipmentModifiers = self.rootStore:get().statModifiers
  local nextX, nextY, totalMoveSpeed = handleMovement(self, dt)
  handleAnimation(self, dt, nextX, nextY, totalMoveSpeed)
  handleAbilities(self, dt)
  updateHealthAndEnergy(self.rootStore)

  -- dynamically get the current animation frame's height
  local sx, sy, sw, sh = self.animation.sprite:getViewport()
  local w,h = sw, sh
  -- true center taking into account pivot
  local oX, oY = self.animation:getSourceOffset()

  local actualX, actualY, cols, len = self.colObj:move(nextX, nextY, collisionFilter)
  self.x = actualX
  self.y = actualY
  self.h = h
  self.w = w

  -- update camera to follow player
  camera:setPosition(self.x, self.y)

  local gridX, gridY = Position.pixelsToGridUnits(self.x, self.y, config.gridSize)
  -- update flowfield every x frames since it also considers ai in the way
  -- as blocked positions, so we need to keep this fresh
  local shouldUpdateFlowField = self.prevGridX ~= gridX or self.prevGridY ~= gridY
  if shouldUpdateFlowField and self.mapGrid then
    local flowField, callCount = self.getFlowField(self.mapGrid, gridX, gridY)
    self.flowField = flowField
    self.prevGridX = gridX
    self.prevGridY = gridY
  end
end

local function drawShadow(self, sx, sy, ox, oy)
  -- SHADOW
  love.graphics.setColor(0,0,0,0.2)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y + self.h/2,
    math.rad(self.angle),
    sx,
    -sy / 2,
    ox,
    oy
  )
end

local function drawDebug(self)
  if config.collisionDebug then
    local c = self.colObj
    love.graphics.setColor(1,1,1,0.5)
    local debug = require 'modules.debug'
    debug.boundingBox(
      'fill',
      c.x - c.ox,
      c.y - c.oy,
      c.w,
      c.h,
      false
    )
  end
end

function Player.draw(self)
  local ox, oy = self.animation:getSourceOffset()
  local scaleX, scaleY = 1 * self.dir, 1

  drawShadow(self, scaleX, scaleY, ox, oy)
  drawDebug(self)

  love.graphics.setColor(1,1,1)
  love.graphics.draw(
    animationFactory.atlas,
    self.animation.sprite,
    self.x,
    self.y,
    math.rad(self.angle),
    scaleX,
    scaleY,
    ox,
    oy
  )
end

Player.drawOrder = function(self)
  return self.group:drawOrder(self) + 1
end

Player.final = function(self)
  msgBus.off(self.listeners)
  self.hudRoot:delete(true)
end

return Component.createFactory(Player)
