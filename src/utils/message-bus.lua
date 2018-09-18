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
		local shouldRemove = false
		if subscriber then
			local ret = subscriber(msgType, nextValue)
			shouldRemove = ret == CLEANUP
		end

		if shouldRemove then
			table.remove(t, i)
		else
			i = i + 1
		end
	end
end

local function callSubscribersByTypeAndHandleCleanup(msgHandlers, nextValue)
	local i = 1
	local t = msgHandlers
	local count = #t
	local ret = nextValue
	while (i <= count) do
		local subscriber = t[i]
		ret = subscriber(ret)
		i = i + 1
	end

	return (count == 0) and nil or ret
end

function M.new()
	local msgBus = {
		CLEANUP = CLEANUP
	}
	local allReducers = {}
	local msgHandlers = {}
	local msgHandlersByMessageType = {}

	--[[
	@msgType - Used by a reducer to determine how to handle the value.
	@msgValue - Data for the msg
	]]
	function msgBus.send(msgType, msgValue)
		assert(msgType ~= nil, 'message type must be provided')
		local nextValue = reduceValueAndHandleCleanup(allReducers, msgType, msgValue)
		callSubscribersAndHandleCleanup(msgHandlers, msgType, nextValue)

		local handlersByType = msgHandlersByMessageType[msgType]
		if handlersByType then
			return callSubscribersByTypeAndHandleCleanup(handlersByType, nextValue)
		end
	end

	function msgBus.addReducer(reducer)
		if reducer == nil then
			return
		end
		typeCheck.validate(reducer, typeCheck.FUNCTION)
		allReducers[#allReducers + 1] = reducer
	end

	-- adds a subscriber
	function msgBus.subscribe(handler, messageType)
		if handler == nil then
			return
		end
		typeCheck.validate(handler, typeCheck.FUNCTION)
		msgHandlers[#msgHandlers + 1] = handler
	end

	function msgBus.on(messageType, handler)
		local handlersByType = msgHandlersByMessageType[messageType]
		if (not handlersByType) then
			handlersByType = {}
			msgHandlersByMessageType[messageType] = handlersByType
		end
		table.insert(handlersByType, handler)
		return handler -- this can be used as the reference for removing a handler
	end

	function msgBus.off(messageType, handler)
		local handlersByType = msgHandlersByMessageType[messageType]
		for i=1, #handlersByType do
			local fn = handlersByType[i]
			local isMatch = fn == handler
			if (isMatch) then
				table.remove(handlersByType, i)
				return
			end
		end
	end

	-- this should be used for just debugging and performance monitoring
	function msgBus.getStats()
		return allReducers, msgHandlers, msgHandlersByMessageType
	end

	function msgBus.clearAll()
		allReducers = {}
		msgHandlers = {}
		msgHandlersByMessageType = {}
	end

	return msgBus
end

return M