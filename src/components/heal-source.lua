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
				return 0
			end
			-- return remaining amount
			coroutine.yield(amount)
		else
			coroutine.yield(amountThisTick)
		end
	end
end

function HealSource.remove(self, healSource)
	self.healSources[healSource.source] = nil
end

local function updateHealth(rootStore, changeAmount)
  local state = rootStore:get()
  local curHealth = state.health
  local maxHealth = state.maxHealth + state.statModifiers.maxHealth
  local newHealth = curHealth + changeAmount
  if newHealth > maxHealth then
    newHealth = maxHealth
  end
  rootStore:set('health', newHealth)
end

function HealSource.add(self, healSource, rootStore)
	self.healSources = self.healSources or {}
	local currentSource = self.healSources[healSource.source]

	local instantHeal = healSource.duration == 0
	if instantHeal then
		return updateHealth(rootStore, healSource.amount)
	end

	local tickRate = 0.05 -- seconds

	self.handle = self.handle or tick.recur(
		function()
			local heal = 0
			-- iterate over all sources and accumulate total heal amount for this tick
			for source,healRoutine in pairs(self.healSources) do
				hasMore, amount = coroutine.resume(healRoutine)
				if not hasMore then
					HealSource.remove(self, source)
				else
					heal = heal + amount
				end
			end
			updateHealth(rootStore, heal)
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