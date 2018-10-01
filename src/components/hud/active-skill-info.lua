local Component = require 'modules.component'
local groups = require 'components.groups'
local msgBus = require 'components.msg-bus'
local camera = require 'components.camera'
local Color = require 'modules.color'
local drawItem = require 'components.item-inventory.draw-item'
local config = require 'config.config'
local setProp = require 'utils.set-prop'

local keyMap = config.keyboard
local mouseInputMap = config.mouseInputMap

local function ActiveConsumableHandler()
  local curCooldown = 0
  local skillCooldown = 0
  local activeItem = nil
  local max = math.max
  local itemDefinitions = require("components.item-inventory.items.item-definitions")
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
      local activateFn = itemDefinitions.getModuleById(activeItem.onActivateWhenEquipped).active
      if not activateFn then
        return skill
      end
      local instance = activateFn(activeItem)
      curCooldown = instance.cooldown
      skillCooldown = instance.cooldown
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
    local itemDefinitions = require("components.item-inventory.items.item-definitions")
    local renderFn = itemDefinitions.getDefinition(activeItem).render
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
  local itemDefinitions = require("components.item-inventory.items.item-definitions")

  local floor = math.floor
  local function modifyAbility(instance, modifiers)
    local v = instance
    local m = modifiers
    local totalFlatWeaponDamage = m.weaponDamage
    local totalWeaponDmg = v.weaponDamageScaling * totalFlatWeaponDamage
    local dmgMultiplier = 1 + m.percentDamage
    local min = floor((v.minDamage * dmgMultiplier) + m.flatDamage + totalWeaponDmg)
    local max = floor((v.maxDamage * dmgMultiplier) + m.flatDamage + totalWeaponDmg)

    -- update instance properties
    v:set('minDamage', min)
      :set('maxDamage', max)
      :set('cooldown', v.cooldown - (v.cooldown * m.cooldownReduction))

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
      local definition = itemDefinitions.getDefinition(activeItem)
      local activateFn = definition.onActivateWhenEquipped
      local energyCost = definition.energyCost(activeItem)
      -- time an attack takes to finish (triggers a global cooldown)
      local curState = self.rootStore:get()
      local enoughEnergy = (energyCost == nil) or
        (energyCost <= curState.energy)
      if (not enoughEnergy) then
        msgBus.send(msgBus.PLAYER_ACTION_ERROR, 'not enough energy')
        return skill
      end

      if (not activateFn) then
        return skill
      end

      local attackTime = definition.attackTime or 0.1
      local actualAttackTime = attackTime - (attackTime * curState.statModifiers.attackTimeReduction)
      playerRef:set('attackRecoveryTime', actualAttackTime)
      msgBus.send(
        msgBus.PLAYER_WEAPON_ATTACK,
        { attackTime = actualAttackTime }
      )

      local mx, my = camera:getMousePosition()
      local playerX, playerY = self.player:getPosition()
      local instance = modifyAbility(
        activateFn(activeItem, setProp({
            x = playerX
          , y = playerY
          , x2 = mx
          , y2 = my
        })),
        curState.statModifiers
      )
      curCooldown = instance.cooldown
      skillCooldown = instance.cooldown

      local actualEnergyCost = energyCost -
        (energyCost * curState.statModifiers.energyCostReduction)
      self.rootStore:set(
        'energy',
        curState.energy - actualEnergyCost
      )
      return skill
    end
  end

  function skill.updateCooldown(dt)
    curCooldown = max(0, curCooldown - dt)
    if activeItem then
      local itemUpdateFn = itemDefinitions.getDefinition(activeItem).update
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
    local itemDefinitions = require("components.item-inventory.items.item-definitions")
    local renderFn = itemDefinitions.getDefinition(activeItem).render
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

local ActiveSkillInfo = {
  group = groups.hud,
  x = 0,
  y = 0,
  skillId = nil,
  slotX = 1,
  slotY = 1,
  size = 28,
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

  self.itemRender = ItemRender.create({
    draw = function()
      love.graphics.setColor(1,1,1)
      skillHandlers[parent.skillId].draw(parent)
    end,
    drawOrder = function(self)
      return self.group:drawOrder(self) + 3
    end
  })
end

function ActiveSkillInfo.update(self, dt)
  updateAbilities(self, dt)
end

local mouseBtnToString = {
  [1] = 'lm',
  [2] = 'rm'
}

local function drawHotkEy(self)
  local mouseBtn = config.mouseInputMap[self.skillId]
  local keyboardKey = config.keyboard[self.skillId]
  local hotKeyToShow = mouseBtn and mouseBtnToString[mouseBtn] or keyboardKey
  self.hudTextLayer:add(
    hotKeyToShow,
    Color.WHITE,
    self.x,
    self.y - 5
  )
end

function ActiveSkillInfo.draw(self)
  local boxSize = self.size

  drawHotkEy(self)

  love.graphics.setColor(0,0,0,0.8)
  love.graphics.rectangle('fill', self.x, self.y, boxSize, boxSize)
  love.graphics.setColor(1,1,1)
  love.graphics.rectangle('line', self.x, self.y, boxSize, boxSize)

  local activeItem = self.rootStore:get().equipment[self.slotY][self.slotX]
  if activeItem then
    drawItem(activeItem, self.x, self.y, boxSize)

    local cooldown, skillCooldown = skillHandlers[self.skillId].getStats()
    local progress = (skillCooldown - cooldown) / skillCooldown
    local offsetY = progress * boxSize
    love.graphics.setColor(1,1,1,0.2)
    love.graphics.rectangle('fill', self.x, self.y + offsetY, boxSize, boxSize - offsetY)

    if cooldown > 0 then
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
      love.graphics.rectangle('fill', self.x, self.y, boxSize, boxSize)
      love.graphics.setBlendMode('alpha')
    end
  end
end

function ActiveSkillInfo.final(self)
  msgBus.off(self.listeners)
end

return Component.createFactory(ActiveSkillInfo)