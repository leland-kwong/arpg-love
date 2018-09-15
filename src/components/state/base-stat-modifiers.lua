local base = {
	energyRegeneration = 1
}

return function()
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
		flatPhysicalDamageReduction = 0,
		cooldownReduction = 0, -- multiplier
		moveSpeed = 0, -- flat increase
		resistFire = 0,
		resistCold = 0,
		resistLightning = 0,
		resistAcid = 0,
		experienceMultiplier = 0 -- increases experience gained by percentage amount
	}
end