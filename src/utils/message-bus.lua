local noop = require('utils.noop')
local typeCheck = require('utils.type-check')

local MESSAGE_TYPE_ALL = '*'

-- module object
local M = {}

-- value that signifies the function is done and should be removed from the list
local CLEANUP = {}
local EMPTY = {}

local function callSubscribersByTypeAndHandleCleanup(self, msgType, queue, msgHandlers, wildCardListeners, nextValue)
	local handlerCount = msgHandlers and #msgHandlers or 0
	local wildcardHandlerCount = wildCardListeners and #wildCardListeners or 0
	local totalHandlerCount = handlerCount + wildcardHandlerCount
	if totalHandlerCount == 0 then
		return nil
	end

	local ret = nextValue
	local callback = function(handlerRef)
		local h = handlerRef
		local handler, filter = h[1], h[4]
		if filter then
			local shouldCall = filter and filter(ret)
			if (not shouldCall) then
				return
			end
		end

		local result = handler(ret, msgType)
		if result == CLEANUP then
			self.off(handlerRef)
		-- when the value is nil, we'll use the previous return value as the return value
		elseif result ~= nil then
			ret = result
		end
	end

	for i=1, handlerCount do
		local h = msgHandlers[i]
		local priority = h[2]
		queue:add(priority, callback, h)
	end

	for i=1, wildcardHandlerCount do
		local h = wildCardListeners[i]
		local priority = h[2]
		queue:add(priority, callback, h)
	end

	queue:flush()
	return ret
end

local Q = require 'modules.queue'

local function tableIfNeeded(t, key)
	if (not t[key]) then
		t[key] = {}
	end
	return t[key]
end

function M.new()
	local msgBus = {
		CLEANUP = CLEANUP,
		ALL = MESSAGE_TYPE_ALL
	}
	local msgHandlersByMessageType = {}
	local queue = Q:new()

	--[[
	@msgType - Used by a reducer to determine how to handle the value.
	@msgValue - Data for the msg
	]]
	function msgBus.send(msgType, msgValue)
		assert(msgType ~= nil, 'message type must be provided')
		local handlersByType = msgHandlersByMessageType[msgType]
		local wildCardListeners = msgHandlersByMessageType[MESSAGE_TYPE_ALL]
		return callSubscribersByTypeAndHandleCleanup(msgBus, msgType, queue, handlersByType, wildCardListeners, msgValue)
	end

	function msgBus.on(messageType, handler, priority, filter)
		assert(type(messageType) ~= nil, 'message type must be a non-nil value')

		local handlersByType = tableIfNeeded(msgHandlersByMessageType, messageType)
		local handlerRef = {handler, priority or 2, messageType, filter}
		handlerRef.isListener = true
		table.insert(handlersByType, handlerRef)

		return handlerRef -- this can be used as the reference for removing a handler
	end

	function msgBus.off(handlerRef)
		if not handlerRef then
			return
		end

		local isMultipleRefs = not handlerRef.isListener
		if isMultipleRefs then
			for i=1, #handlerRef do
				msgBus.off(handlerRef[i])
			end
			return
		end

		local messageType = handlerRef[3]
		local handlersByType = msgHandlersByMessageType[messageType]
		for i=1, #handlersByType do
			local ref = handlersByType[i]
			local isMatch = ref == handlerRef
			if (isMatch) then
				table.remove(handlersByType, i)
				return
			end
		end
	end

	-- this should be used for just debugging and performance monitoring
	function msgBus.getStats()
		return msgHandlersByMessageType
	end

	function msgBus.clearAll()
		msgHandlersByMessageType = {}
	end

	return msgBus
end

return M