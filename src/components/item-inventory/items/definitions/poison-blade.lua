local utils = require("main.utils")
local Audio = require("main.audio.audio")
local config = require("main.components.items.config")
local msgBus = require("main.state.msg-bus")
local itemDefs = require("main.components.items.item-definitions")

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

return itemDefs.registerType({
	type = "POISON_BLADE",

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
		sprite = "poison-blade",
		title = 'Blade of the plague bearer',
		rarity = config.rarity.LEGENDARY,
		category = config.category.WEAPON_1,

		tooltip = function(self)
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				local typeText = #type > 0 and " <color=white>"..type.."</color>" or ""
				return "<color="..color..">"..sign..stat.."</color>"..typeText
			end
			local _state = self.state
			local stats = {
				"<font=body>"..statValue(_state.baseDamage, "cyan", "").." ("..statValue(_state.bonusDamage, "cyan", "")..") damage</font>",
				"<font=body>"..statValue(self.poisonDamage, "cyan", "poison damage").."</font>",
				"\n<font=body>While equipped: \nPermanently gain +1 damage for every 10 enemies killed. \n<color=cyan>".._state.enemiesKilled.."</color> enemies killed".."</font>"
			}
			local concat = function(separator)
				return function(seed, string, index)
					seed = seed or ""
					if index > 1 then
						return seed..separator..string
					else
						return seed..string
					end
				end
			end
			return utils.functional.reduce(stats, concat("\n"))
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