local noop = require('utils.noop')
local typeCheck = require('utils.type-check')

-- module object
local M = {}

-- value that signifies the function is done and should be removed from the list
local CLEANUP = {}

--[[
	This function has been heavily optimized to make function deletion as cheap as possible.
	This is achieved by deleting the function and compacting the table all in the same loop.
]]
local function reduceValueAndHandleCleanup(allReducers, msgType, msgValue)
	local nextValue = msgValue
	local j = 0
	local i = 1
	local t = allReducers
	-- this is cached to prevent length counting on every iteration even if it hasn't changed
	while (i <= #t) do
		local reducer = t[i]
		local ret = nil
		local shouldRemove = false
		if reducer then
			ret = reducer(msgType, nextValue)
			shouldRemove = ret == CLEANUP
			nextValue = shouldRemove and nextValue or ret
		end
		if shouldRemove then
			table.remove(t, i)
		else
			i = i + 1
		end
	end

	return nextValue
end

local function callSubscribersAndHandleCleanup(msgHandlers, msgType, nextValue)
	local j = 0
	local i = 1
	local t = msgHandlers
	while (i <= #t) do
		local subscriber = t[i]
		local ret = nil
		local shouldRemove = false
		if subscriber then
			ret = subscriber(msgType, nextValue)
			shouldRemove = ret == CLEANUP
		end

		if shouldRemove then
			table.remove(t, i)
		else
			i = i + 1
		end
	end
end

function M.new()
	local msgBus = {
		CLEANUP = CLEANUP
	}
	local allReducers = {}
	local msgHandlers = {}

	--[[
	@msgType - Used by a reducer to determine how to handle the value.
	@msgValue - Data for the msg
	]]
	function msgBus.send(msgType, msgValue)
		assert(msgType ~= nil, 'message type must be provided')
		local nextValue = reduceValueAndHandleCleanup(allReducers, msgType, msgValue)
		callSubscribersAndHandleCleanup(msgHandlers, msgType, nextValue)
	end

	function msgBus.addReducer(reducer)
		if reducer == nil then
			return
		end
		typeCheck.validate(reducer, typeCheck.FUNCTION)
		allReducers[#allReducers + 1] = reducer
	end

	-- adds a subscriber
	function msgBus.subscribe(handler)
		if handler == nil then
			return
		end
		typeCheck.validate(handler, typeCheck.FUNCTION)
		msgHandlers[#msgHandlers + 1] = handler
	end

	-- this should be used for just debugging and performance monitoring
	function msgBus.getStats()
		return allReducers, msgHandlers
	end

	function msgBus.clearAll()
		allReducers = {}
		msgHandlers = {}
	end

	return msgBus
end

return M