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

return setmetatable({
	--[[
		TODO: add prop type handlers for transforming values. This way we can easily see how properties are being calculated.
	]]
	propTypesDisplayValue = setmetatable({
		attackTime = valueTypeHandlers.time,
		cooldown = valueTypeHandlers.time,
		attackTimeReduction = valueTypeHandlers.percent,
		percentDamage = valueTypeHandlers.percent,
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
		return {
			flatDamage = 0,
			percentDamage = 0,
			weaponDamage = 0, -- total weapon damage from items
			energyCostReduction = 0, -- multiplier
			maxHealth = 0,
			maxEnergy = 0,
			healthRegeneration = 0,
			energyRegeneration = base.energyRegeneration,
			armor = 0,
			flatPhysicalReduction = 0,
			cooldownReduction = 0, -- multiplier
			attackTimeReduction = 0, -- multiplier
			moveSpeed = 0, -- flat increase
			fireResist = 0,
			coldResist = 0,
			lightningResist = 0,
			experienceMultiplier = 0 -- increases experience gained by percentage amount
		}
	end
})