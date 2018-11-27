return function(ability)
	-- physical damage
	return math.random(
		ability.minDamage or 0,
		ability.maxDamage or 0
	)
end