local Enum = require 'utils.enum'
local round = require 'utils.math'.round

local base = {
	energyRegeneration = 1
}

local valueTypeHandlers = {
	percent = function(v)
		return round(v * 100)..'%'
	end,
	time = function(v)
		return v..'s'
	end
}

local function passThrough(v)
	return v > 0 and round(v) or v
end

local baseStatModifiersMt = {
	apply = function(self, prop, value)
		self[prop] = self[prop] + value
		return self
	end
}
baseStatModifiersMt.__index = baseStatModifiersMt

return setmetatable({
	--[[
		TODO: add prop type handlers for transforming values. This way we can easily see how properties are being calculated.
	]]
	propTypesDisplayValue = setmetatable({
		attackTime = valueTypeHandlers.time,
		cooldown = valueTypeHandlers.time,
		attackSpeed = valueTypeHandlers.percent,
		energyCostReduction = valueTypeHandlers.percent,
		cooldownReduction = valueTypeHandlers.percent,
	}, {
		__index = function()
			return passThrough
		end
	}),

	propTypesCalculator = setmetatable({
		cooldownReduction = function(cooldown, reduction)
			return math.max(0, cooldown - (cooldown * reduction))
		end,
		--[[
			attack speed increases the number of actions per second
		]]
		attackSpeed = function(attackTime, bonusAttackSpeed)
			local attacksPerSec = 1/attackTime
			local newAttackRate = (attacksPerSec * (bonusAttackSpeed + 1))
			local newAttackTime = 1/newAttackRate
			print(newAttackRate, newAttackTime)
			return newAttackTime
		end
	}, {
		__index = function()
			return passThrough
		end
	})
}, {
	__call = function()
		return setmetatable({
			attackPower = 0, -- total damage increase
			energyCostReduction = 0, -- multiplier
			maxHealth = 0,
			maxEnergy = 0,
			healthRegeneration = 0,
			energyRegeneration = base.energyRegeneration,
			armor = 0,
			cooldownReduction = 0, -- multiplier
			attackSpeed = 0, -- multiplier
			moveSpeed = 0, -- flat increase
			fireResist = 0,
			coldResist = 0,
			lightningResist = 0,
		}, baseStatModifiersMt)
	end
})