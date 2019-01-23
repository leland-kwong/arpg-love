local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local camera = require 'components.camera'
local Color = require 'modules.color'
local drawItem = require 'components.item-inventory.draw-item'
local config = require 'config.config'
local userSettings = require 'config.user-settings'
local setProp = require 'utils.set-prop'
local extend = require 'utils.object-utils'.extend
local Vec2 = require 'modules.brinevector'
local propTypesCalculator = require 'components.state.base-stat-modifiers'.propTypesCalculator
local itemSystem = require('components.item-inventory.items.item-system')

local keyMap = userSettings.keyboard
local mouseInputMap = userSettings.mouseInputMap

local function ActiveConsumableHandler()
  local curCooldown = 0
  local skillCooldown = 0
  local activeItem = nil
  local max = math.max
  local skill = {
    type = 'CONSUMABLE'
  }

  function skill.set(item)
    local isDifferentSkill = item ~= activeItem
    -- reset cooldown
    if (item and isDifferentSkill) then
      curCooldown = 0
    end
    activeItem = item
  end

  function skill.use(self)
    if (not activeItem) or (curCooldown > 0) then
      return skill
    else
      local activateFn = itemSystem.loadModule(itemSystem.getDefinition(activeItem).onActivateWhenEquipped).active
      if not activateFn then
        return skill
      end
      activateFn(activeItem)
      local baseCooldown = itemSystem.getDefinition(activeItem).info.cooldown or 0
      local actualCooldown = propTypesCalculator.cooldownReduction(baseCooldown, Component.get('PLAYER').stats:get('cooldownReduction'))
      curCooldown = actualCooldown
      skillCooldown = actualCooldown
      return skill
    end
  end

  function skill.updateCooldown(dt)
    curCooldown = max(0, curCooldown - dt)
    return skill
  end

  function skill.getStats()
    return curCooldown, skillCooldown
  end

  function skill.draw(self)
    if (not activeItem) then
      return
    end
    local renderFn = itemSystem.getDefinition(activeItem).render
    if renderFn then
      renderFn(activeItem)
    end
  end

  return skill
end

local function ActiveEquipmentHandler()
  local max = math.max
  local curCooldown = 0
  local skillCooldown = 0
  local activeItem = nil
  local skill = {
    type = 'EQUIPMENT'
  }

  local round = require 'utils.math'.round
  local function modifyAbility(instance, playerRef)
    local v = setProp(instance)
    local dmgMultiplier = 1 + (playerRef.stats:get('actionPower') / 100)
    local min = (v.minDamage or 0) * dmgMultiplier
    local max = (v.maxDamage or 0) * dmgMultiplier

    -- update instance properties
    v:set('minDamage', min)
      :set('maxDamage', max)
    if v.lightningDamage then
      v:set('lightningDamage', v.lightningDamage * dmgMultiplier)
    end
    if v.coldDamage then
      v:set('coldDamage', v.coldDamage * dmgMultiplier)
    end

    return v
  end

  function skill.set(item)
    local isDifferentSkill = item ~= activeItem
    -- reset cooldown
    if (item and isDifferentSkill) then
      curCooldown = 0
    end
    activeItem = item
  end

  function skill.use(self)
    local playerRef = Component.get('PLAYER')
    if (not activeItem) or (curCooldown > 0) or (playerRef.attackRecoveryTime > 0) then
      return skill
    else
      local definition = itemSystem.getDefinition(activeItem)
      local activateModule = itemSystem.loadModule(itemSystem.getDefinition(activeItem).onActivateWhenEquipped)
      local activateFn = activateModule and activateModule.active
      local energyCost = itemSystem.getDefinition(activeItem).info.energyCost
      -- time an attack takes to finish (triggers a global cooldown)
      local playerRef = Component.get('PLAYER')
      local enoughEnergy = (energyCost == nil) or
        (energyCost <= playerRef.energy)
      if (not enoughEnergy) then
        msgBus.send(msgBus.PLAYER_ACTION_ERROR, 'not enough energy')
        return skill
      end

      if (not activateFn) then
        return skill
      end

      local actionSpeed = itemSystem.getDefinition(activeItem).info.actionSpeed or 0
      local actualAttackTime = propTypesCalculator.increasedActionSpeed(actionSpeed, Component.get('PLAYER').stats:get('increasedActionSpeed'))

      local mx, my = camera:getMousePosition()
      local playerX, playerY = self.player:getPosition()
      local abilityData = activateFn(activeItem)
      local abilityEntity = abilityData.blueprint.create(
        modifyAbility(
          extend(
            abilityData.props, {
              actionSpeed = actualAttackTime
            , x = playerX
            , y = playerY
            , x2 = mx
            , y2 = my
            , source = activeItem.__id
          }),
          playerRef
        )
      )
      local baseCooldown = itemSystem.getDefinition(activeItem).info.cooldown or 0
      local actualCooldown = propTypesCalculator.cooldownReduction(baseCooldown, Component.get('PLAYER').stats:get('cooldownReduction'))
      curCooldown = actualCooldown
      skillCooldown = actualCooldown

      playerRef:set('attackRecoveryTime', actualAttackTime)
      msgBus.send(
        msgBus.PLAYER_WEAPON_ATTACK,
        {
          actionSpeed = actualAttackTime,
          source = activeItem.__id,
          fromPos = Vec2(playerX, playerY),
          targetPos = Vec2(mx, my)
        }
      )

      local actualEnergyCost = energyCost -
        (energyCost * playerRef.stats:get('energyCostReduction'))
      playerRef.energy = playerRef.energy - actualEnergyCost
      return skill
    end
  end

  function skill.updateCooldown(dt)
    curCooldown = max(0, curCooldown - dt)
    if activeItem then
      local itemUpdateFn = itemSystem.getDefinition(activeItem).update
      if itemUpdateFn then
        itemUpdateFn(activeItem, dt)
      end
    end
    return skill
  end

  function skill.getStats()
    return curCooldown, skillCooldown
  end

  function skill.draw(self)
    if (not activeItem) then
      return skill
    end
    local renderFn = itemSystem.getDefinition(activeItem).render
    if renderFn then
      renderFn(activeItem)
    end
  end

  return skill
end

local skillHandlers = {

  SKILL_1 = ActiveEquipmentHandler(),
  SKILL_2 = ActiveEquipmentHandler(),
  SKILL_3 = ActiveEquipmentHandler(),
  SKILL_4 = ActiveEquipmentHandler(),

  MOVE_BOOST = ActiveConsumableHandler(),
  ACTIVE_ITEM_1 = ActiveConsumableHandler(),
  ACTIVE_ITEM_2 = ActiveConsumableHandler()
}

-- sets the new ability if it has changed and also updates the cooldown
local function updateAbilities(self, dt)
  local item = self.rootStore:get().equipment[self.slotY][self.slotX]
  skillHandlers[self.skillId].set(item)
  skillHandlers[self.skillId].updateCooldown(dt)
end

local SkillBarPreDraw = Component.create({
  setSkill = function(self, skillId, drawFn)
    self.drawBySkillId[skillId] = drawFn
  end,
  init = function(self)
    Component.addToGroup(self, 'hud')
    self.drawBySkillId = {}
  end,
  draw = function(self)
    love.graphics.setColor(1,1,1)
    for _,drawFn in pairs(self.drawBySkillId) do
      drawFn()
    end
  end,
  drawOrder = function()
    return 2
  end
})

local ActiveSkillInfo = {
  group = groups.hud,
  x = 0,
  y = 0,
  skillId = nil,
  slotX = 1,
  slotY = 1,
  size = 26,
  player = nil,
  rootStore = nil
}

local ItemRender = {
  group = groups.all,
}
Component.createFactory(ItemRender)

function ActiveSkillInfo.init(self)
  local parent = self
  assert(self.skillId ~= nil, '[HUD activeItem] skillId is required')
  assert(skillHandlers[self.skillId] ~= nil, '[HUD activeItem] `skillId`'..self.skillId..' is not defined')
  assert(self.player ~= nil, '[HUD activeItem] property `player` is required')
  assert(self.rootStore ~= nil, '[HUD activeItem] property `rootStore` is required')

  self.listeners = {
    msgBus.on(msgBus.PLAYER_USE_SKILL, function(value)
      if value == self.skillId then
        skillHandlers[self.skillId].use(self)
      end
      return value
    end)
  }

  self.canvas = love.graphics.newCanvas()
end

function ActiveSkillInfo.update(self, dt)
  updateAbilities(self, dt)

  local nextActiveItem = self.rootStore:get().equipment[self.slotY][self.slotX]
  local isNewItem = nextActiveItem ~= self.activeItem
  if (isNewItem) then
    SkillBarPreDraw:setSkill(
      self:getId(),
      function()
        local boxSize = self.size

        if nextActiveItem then
          drawItem(nextActiveItem, self.x, self.y, boxSize)
        end
      end
    )
  end
  self.activeItem = nextActiveItem
end

local Constants = require 'components.state.constants'
local mouseBtnToString = {
  [1] = Constants.glyphs.leftMouseBtn,
  [2] = Constants.glyphs.rightMouseBtn
}

local keyboardBtnToString = {
  space = 'spc'
}

local function drawHotkEy(self)
  local userSettings = require 'config.user-settings'
  local mouseBtn = userSettings.mouseInputMap[self.skillId]
  local keyboardKey = userSettings.keyboard[self.skillId]
  local hotKeyToShow = mouseBtnToString[mouseBtn] or keyboardBtnToString[keyboardKey] or keyboardKey
  self.hudTextLayer:add(
    hotKeyToShow,
    Color.WHITE,
    self.x + 2,
    self.y + self.size - 9
  )
end

function ActiveSkillInfo.draw(self)
  drawHotkEy(self)

  if self.activeItem then
    local boxSize = self.size
    local cooldown, skillCooldown = skillHandlers[self.skillId].getStats()

    local AnimationFactory = require 'components.animation-factory'
    local pixel = AnimationFactory:newStaticSprite('pixel-white-1x1')
    if cooldown > 0 then
      local progress = (skillCooldown - cooldown) / skillCooldown
      local offsetY = progress * boxSize
      love.graphics.setColor(1,1,1,0.2)
      -- white box showing cooldown
      pixel:draw(self.x, self.y + offsetY, 0, boxSize, boxSize - offsetY)

      local p = 5 -- padding
      self.hudTextLayer:add(
        string.format('%.1f', cooldown),
        Color.WHITE,
        self.x + p,
        self.y + p
      )
    end

    local attackRecoveryTime = Component.get('PLAYER').attackRecoveryTime
    local skill = skillHandlers[self.skillId]
    if (attackRecoveryTime > 0) and (skill.type == 'EQUIPMENT') then
      love.graphics.setBlendMode('add')
      love.graphics.setColor(1,0,0,0.4)
      -- box overlay showing skill unable to be used
      pixel:draw(self.x, self.y, 0, boxSize, boxSize)
      love.graphics.setBlendMode('alpha')
    end
  end
end

function ActiveSkillInfo.drawOrder()
  return SkillBarPreDraw:drawOrder() + 0.1
end

function ActiveSkillInfo.final(self)
  msgBus.off(self.listeners)

  SkillBarPreDraw:setSkill(self:getId(), nil)
end

return Component.createFactory(ActiveSkillInfo)