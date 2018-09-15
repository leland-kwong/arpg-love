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
	self.flatDamage = s.bonusDamage
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

local MUZZLE_FLASH_COLOR = {Color.rgba255(232, 187, 27, 1)}
local muzzleFlashMessage = {
	color = MUZZLE_FLASH_COLOR
}

return itemDefs.registerType({
	type = 'pod-module-fireball',

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
		sprite = "weapon-module-fireball",
		title = 'tz-819 mortar',
		rarity = config.rarity.LEGENDARY,
		category = config.category.POD_MODULE,

		levelRequirement = 3,
		attackTime = 0.4,
		energyCost = function(self)
			return 2
		end,

		tooltip = function(self)
			local _state = self.state
			local stats = {
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
			Fireball.cooldown = 0.2
			Fireball.startOffset = 26
			msgBus.send(msgBus.PLAYER_WEAPON_MUZZLE_FLASH, muzzleFlashMessage)

			local Sound = require 'components.sound'
			love.audio.play(Sound.functions.fireBlast())
			return Fireball.create(props)
		end,

		onMessage = function(self, msgType)
			if msgBus.ENEMY_DESTROYED == msgType then
				onEnemyDestroyedIncreaseDamage(self)
			end
		end
	}
})