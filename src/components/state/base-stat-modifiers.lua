local Enum = require 'utils.enum'

local base = {
	energyRegeneration = 1
}

local valueTypeHandlers = {
	percent = function(v)
		return (v * 100)..'%'
	end,
	time = function(v)
		return v..'s'
	end
}

local function passThrough(v)
	return v
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
		attackTimeReduction = valueTypeHandlers.percent,
		attackPower = valueTypeHandlers.percent,
		energyCostReduction = valueTypeHandlers.percent,
		cooldownReduction = valueTypeHandlers.percent,
	}, {
		__index = function()
			return passThrough
		end
	}),

	propTypesCalculator = setmetatable({
		cooldownReduction = function(cooldown, reduction)
			return cooldown - (cooldown * reduction)
		end,
		attackTimeReduction = function(attackTime, reduction)
			return attackTime - (attackTime * reduction)
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
			physicalReduction = 0,
			cooldownReduction = 0, -- multiplier
			attackTimeReduction = 0, -- multiplier
			moveSpeed = 0, -- flat increase
			fireResist = 0,
			coldResist = 0,
			lightningResist = 0,
			experienceMultiplier = 0 -- increases experience gained by percentage amount
		}, baseStatModifiersMt)
	end
})