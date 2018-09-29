local tick = require 'utils.tick'
local HealSource = {}

local function healRoutine(healSource, tickRate)
	local amount = healSource.amount
	local duration = healSource.duration
	local amountPerTick = (amount / healSource.duration) * tickRate
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

		amount = amount - amountThisTick

		if amount < amountThisTick then
			if amount <= 0 then
				return 0, healSource.property, healSource.maxProperty
			end
			-- return remaining amount
			coroutine.yield(amount, healSource.property, healSource.maxProperty)
		else
			coroutine.yield(amountThisTick, healSource.property, healSource.maxProperty)
		end
	end
end

function HealSource.remove(self, source)
	if not self.healSources then
		return
	end
	self.healSources[source] = nil
end

local min, max = math.min, math.max
local function updateProperty(rootStore, changeAmount, property, maxProperty)
  local state = rootStore:get()
  local curProp = state[property]
  local maxProp = state[maxProperty] + state.statModifiers[maxProperty]
	local newProp = max(0, min(maxProp, curProp + changeAmount))
  rootStore:set(property, newProp)
end

function HealSource.add(self, healSource, rootStore)
	self.healSources = self.healSources or {}
	local currentSource = self.healSources[healSource.source]

	local instantHeal = healSource.duration == 0
	if instantHeal then
		return updateProperty(
			rootStore,
			healSource.amount,
			healSource.property,
			healSource.maxProperty
		)
	end

	local tickRate = 0.05 -- seconds

	self.handle = self.handle or tick.recur(
		function()
			-- iterate over all sources and accumulate total heal amount for this tick
			for source,healRoutine in pairs(self.healSources) do
				local hasMore, healAmount, property, maxProperty = coroutine.resume(healRoutine)
				if (not hasMore) then
					HealSource.remove(self, source)
				else
					updateProperty(rootStore, healAmount, property, maxProperty)
				end
			end
		end,
		tickRate
	)

	local healCo = coroutine.create(healRoutine)
	-- kick things off
	coroutine.resume(healCo, healSource, tickRate)
	-- replace the current source with a new source
	self.healSources[healSource.source] = healCo
end

return HealSource