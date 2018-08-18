local config = require("main.components.items.config")
local utils = require("main.utils")
local Global = require("main.global")
local msgBus = require("main.state.msg-bus")
local stateById = require("utils.state-by-id")
local itemDefs = require("main.components.items.item-definitions")

local msgFilters = {
	[msgBus.PLAYER_MOVE] = true,
	[msgBus.PLAYER_IDLE] = true
}

local function stackManager(state)
	local stacks = 0
	local maxStacks = 150
	local changeRateByMsgType = {
		[msgBus.PLAYER_MOVE] = 2,
		[msgBus.PLAYER_IDLE] = -4,
		default = 0
	}

	while not state.done do
		local changeAmount = changeRateByMsgType[state.msgType]
			or changeRateByMsgType.default

		stacks = stacks + changeAmount

		if stacks > maxStacks then
			stacks = maxStacks
		end

		if stacks < 0 then
			stacks = 0
		end

		coroutine.yield(stacks)
	end
end

return itemDefs.registerType({
	type = "FLIGHT_FOOT",

	create = function()
		return {
			stackSize = 1,
			maxStackSize = 1,

			armor = 20,
			moveSpeed = 100,
		}
	end,

	properties = {
		sprite = "shoes-1",
		title = 'Flight Foot',
		rarity = config.rarity.LEGENDARY,
		category = config.category.SHOES,

		tooltip = function(self)
			local function statValue(stat, color, type)
				local sign = stat >= 0 and "+" or "-"
				return "<color="..color..">"..sign..stat.."</color> <color=white>"..type.."</color>"
			end
			local stats = {
				"<font=body>"..statValue(self.armor, "cyan", "armor").."</font>",
				"<font=body>"..statValue(self.moveSpeed, "cyan", "move speed").."</font>"
			}
			local concat = function(separator)
				return function(seed, string, index)
					seed = seed or ""
					local separator = index > 1 and separator or ""
					return seed..separator..string
				end
			end
			return utils.functional.reduce(stats, concat("\n"))
		end,

		modifier = function(self, msgType, msgValue, CLEANUP)
			if msgFilters[msgType] then
				local s = stateById:get(self.__id)

				s.msgType = msgType

				if not s.stackManager then
					s.stackManager = coroutine.create(stackManager)
				end

				local alive, bonusSpeed = coroutine.resume(s.stackManager, s)

				if not alive and Global.isDebug then
					-- show error
					error(moveStacks)
				end

				msgValue.modifier = msgValue.modifier + bonusSpeed
				return msgValue
			else
				-- just pass through and do nothing
				return msgValue
			end
		end,

		final = function(self)
			local s = stateById:done(self.__id)
			if s.stackManager then
				-- run one last time to clean things up
				coroutine.resume(s.stackManager, s)
			end
		end,

		onActivate = function(self)
			local toSlot = itemDefs.getDefinition(self).category
			msgBus.send(msgBus.EQUIPMENT_SWAP, {
				self,
				toSlot,
			})
		end,
	}
})