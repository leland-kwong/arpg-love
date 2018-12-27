local tick = require 'utils.tick'
local HealSource = {}

local function healRoutine(healSource, tickRate)
	local amount = healSource.amount
	local duration = healSource.duration or 0
	local isInstantHeal = duration == 0
	local amountPerTick = isInstantHeal
		and amount
		or (amount / duration * tickRate)

	-- we want to heal in integer amounts, so we store fractional remainders
	local remainder = 0

	-- first call is just to kick things off
	coroutine.yield()

	while true do
		local amountThisTick = amountPerTick
		local fractional = amountThisTick % 1
		amountThisTick = amountThisTick - fractional
		remainder = remainder + fractional

		if remainder >= 1 then
			amountThisTick = amountThisTick + 1
			remainder = remainder - 1
		end

		if amount < amountThisTick then
			if amount <= 0 then
				return 0, healSource.property, healSource.maxProperty
			end
			-- return remaining amount
			coroutine.yield(amount, healSource.property, healSource.maxProperty)
		else
			coroutine.yield(amountThisTick, healSource.property, healSource.maxProperty)
		end

		amount = amount - amountThisTick
	end
end

function HealSource.remove(self, source)
	if not self.healSources then
		return
	end
	self.healSources[source] = nil
end

local min, max = math.min, math.max
local function updateProperty(self, changeAmount, property, maxProperty)
	if (changeAmount == 0) then
		return
	end
  local curProp = self[property]
  local maxProp = self.stats:get(maxProperty)
	local newVal = max(0, min(maxProp, curProp + changeAmount))
	self[property] = newVal
end

function HealSource.add(self, healSource)
	self.healSources = self.healSources or {}
	local tickRate = 0.05 -- seconds

	self.handle = self.handle or tick.recur(
		function()
			-- iterate over all sources and accumulate total heal amount for this tick
			for source,healRoutine in pairs(self.healSources) do
				local hasMore, healAmount, property, maxProperty = coroutine.resume(healRoutine)
				if (not hasMore) then
					HealSource.remove(self, source)
				else
					updateProperty(self, healAmount, property, maxProperty)
				end
			end
		end,
		tickRate
	)

	local healCo = coroutine.create(healRoutine)
	-- kick things off
	coroutine.resume(healCo, healSource, tickRate)
	assert(healSource.source ~= nil, '[heal-source] source must be provided')
	-- replace the current source with a new source
	self.healSources[healSource.source] = healCo
end

return HealSource