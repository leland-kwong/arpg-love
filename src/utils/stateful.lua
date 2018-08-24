--[[

A simple, but fast observable state store with set, get, and onChange callback

]]--

local isDebug = require'config'.isDebug
local F = require("utils.functional")
local objectUtils = require("utils.object-utils")
local typeCheck = require("utils.type-check")
local socket = require'socket'
local tick = require 'utils.tick'

local noop = function() end

local function make__stateId()
	return string.sub(socket.gettime(), 1, 10)
end

local Stateful = {}

local TYPE_FUNCTION = 'function'
local debugAction = {
	SET_PENDING = 'SET_PENDING',
	SET_SUCCESS = 'SET_SUCCESS',
	SET_SUCCESS_NO_CHANGE = 'SET_SUCCESS_NO_CHANGE',
	UPDATE_PENDING = 'UPDATE_PENDING',
	UPDATE_SUCCESS = 'UPDATE_SUCCESS'
}
Stateful.debugAction = debugAction

local defaultOptions = {
	debounceRate = 0.016, -- seconds after a `set` call to trigger a callback
	debug = noop, -- debug function that gets called after each action (SET_PENDING, SET_SUCCESS, etc...)
	pure = true, -- if `set` call has no change in value, then no update will be triggered
}

-- private properties
local __state = {}
local __prevState = {}

function Stateful:new(initialState, options)
	if not isDebug then
		-- remove debug-only options
		options.debug = nil
	end

	initialState = initialState or {} -- create object if user does not provide one
	initialState.__stateId = initialState.__stateId or make__stateId()
	local o = {
		initialState = initialState,
		[__state] = initialState,
		[__prevState] = initialState,
		subscribers = {},
		pendingStateChangeUpdate = false,
		updateCompleteCallbacks = {}, -- table of callbacks to execute when update is complete
	}
	-- apply options
	objectUtils.assign(o, defaultOptions, options)

	setmetatable(o, self)
	self.__index = self

	function o.stateChangeCallback()
		-- subscribers are keyed with unique token for easy unsubscribing
		-- so we can't iterate over them like an array
		for token,cb in pairs(o.subscribers) do
			cb(o.state, o.prevState)
		end
		o.execCallbacks(o.updateCompleteCallbacks)
		o.pendingStateChangeUpdate = false
		o.debug(debugAction.UPDATE_SUCCESS)
	end

	function o.execCallbacks(callbacks)
		for i=1, #callbacks do
			local cb = callbacks[i]
			cb(o.state, o.prevState)
		end
	end

	return o
end

Stateful.INITIAL_VALUE = 'INITIAL_VALUE'

function Stateful:set(key, value, updateCompleteCallback)
	typeCheck.validate(value, typeCheck.NON_NIL)

	self.debug(debugAction.SET_PENDING, key, value)

	local isValueFunction = type(value) == TYPE_FUNCTION
	-- call the value function with current state
	if isValueFunction then
		value = value(self[__state])
	end

	local isNewValue = not self.pure or (self.pure and self[__state][key] ~= value)

	-- no changes, so lets just do nothing
	if not isNewValue then
		self.debug(debugAction.SET_SUCCESS_NO_CHANGE, key, value)
		return self
	end

	if updateCompleteCallback then
		table.insert(self.updateCompleteCallbacks, updateCompleteCallback)
	end

	-- Only change the previous state if things have changed
	-- This makes it easy for us to do state equality comparisons
	if not self.pendingStateChangeUpdate then
		-- set history to current state
		self[__prevState] = self[__state]
		-- copy current state and set it as the new state
		self[__state] = objectUtils.assign({}, self[__state])
	end

	if Stateful.INITIAL_VALUE == value then
		value = self.initialState[key]
	end

	self[__state][key] = value

	-- queue up subscriber update --
	if not self.pendingStateChangeUpdate then
		self.pendingStateChangeUpdate = true
		self.debug(debugAction.UPDATE_PENDING)
		if self.debounceRate > 0 then
			tick.delay(self.stateChangeCallback, self.debounceRate)
		else
			self.stateChangeCallback()
		end
	end

	self.debug(debugAction.SET_SUCCESS, key, value)

	return self
end

function Stateful:get()
	return self[__state], self[__prevState]
end

function Stateful:replaceState(newState)
	-- validate state shape to make sure its same as what it was initially
	if isDebug then
		for k,v in pairs(self.initialState) do
			if newState[k] == nil then
				error("[stateful.replaceState] state shape is incorrect. Missing key `"..k.."`")
			end
		end
	end

	-- use the setter method so we can trigger subscribers
	for k,v in pairs(newState) do
		self:set(k, v)
	end
	return self
end

local subscribeId = 0
function Stateful:subscribe(func)
	if not func then
		return nil
	end
	local token = 'subscriber-'..subscribeId
	self.subscribers[token] = func
	subscribeId = subscribeId + 1
	return token
end

function Stateful:unsubscribe(token)
	self.subscribers[token] = nil
end

return Stateful