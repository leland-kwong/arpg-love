local config = require("components.item-inventory.items.config")
local msgBus = require("components.msg-bus")
local itemDefs = require("components.item-inventory.items.item-definitions")
local Color = require 'modules.color'
local functional = require("utils.functional")

local mathFloor = math.floor

local enemiesPerDamageIncrease = 30
local maxBonusDamage = 2
local baseDamage = 2

local function onEnemyDestroyedIncreaseDamage(self)
	local s = self.state
	s.enemiesKilled = s.enemiesKilled + 1
	s.bonusDamage = mathFloor(s.enemiesKilled / enemiesPerDamageIncrease)
	if s.bonusDamage > maxBonusDamage then
		s.bonusDamage = maxBonusDamage
	end
end

local function statValue(stat, color, type)
	local sign = stat >= 0 and "+" or "-"
	return {
		color, sign..stat..' ',
		{1,1,1}, type
	}
end

local function concatTable(a, b)
	for i=1, #b do
		local elem = b[i]
		table.insert(a, elem)
	end
	return a
end

return itemDefs.registerType({
	type = "poison-blade",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			state = {
				baseDamage = baseDamage,
				bonusDamage = 0,
				enemiesKilled = 0,
			},

			-- static properties
			weaponDamage = baseDamage,
		}
	end,

	properties = {
		sprite = "sword_18",
		title = 'Blade of the plague bearer',
		rarity = config.rarity.LEGENDARY,
		category = config.category.WEAPON_1,

		energyCost = function(self)
			return 2
		end,

		tooltip = function(self)
			local _state = self.state
			local stats = {
				statValue(_state.baseDamage, Color.CYAN, ""), statValue(_state.bonusDamage, Color.CYAN, "damage \n"),
				statValue(self.weaponDamage, Color.CYAN, "poison damage\n"),
				{
					Color.WHITE, '\nWhile equipped: \nPermanently gain +1 damage for every 10 enemies killed.\n',
					Color.CYAN, _state.enemiesKilled, Color.WHITE, ' enemies killed'
				}
			}
			return functional.reduce(stats, function(combined, textObj)
				return concatTable(combined, textObj)
			end, {})
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, self)
		end,

		onActivateWhenEquipped = function(self, props)
			local Fireball = require 'components.fireball'
			Fireball.minDamage = 0
			Fireball.maxDamage = 0
			return Fireball.create(props)
		end,

		onMessage = function(self, msgType)
			if msgBus.ENEMY_DESTROYED == msgType then
				onEnemyDestroyedIncreaseDamage(self)
			end
		end,

		modifier = function(self, msgType, msgValue)
			if msgBus.PLAYER_ATTACK == msgType then
				msgValue.flatDamage = self.state.bonusDamage
			end
			return msgValue
		end
	}
})