return function(ability)
	return {
		-- physical damage
		damage = math.random(
			ability.minDamage or 0,
			ability.maxDamage or 0
		)
	}
end