local messageBus = require("utils.message-bus")
local perf = require("utils.perf")

local function filteredListeners()
	local msgBus = messageBus.new()
	local msgFoo = 'foo'
	local msgBar = 'bar'
	local listener1 = msgBus.on(msgFoo, function()
		return 1
	end)
	local listener2Called = false
	local listener2 = msgBus.on(msgBar, function(input)
		if listener2Called then
			return msgBus.CLEANUP
		end
		listener2Called = true
		return input
	end)
	msgBus.on(msgBar, function(input)
		return input + 1
	end)

	assert(msgBus.send(msgFoo) == 1)
	assert(msgBus.send(msgBar, 1) == 2)

	msgBus.off(msgFoo, listener1)
	assert(msgBus.send(msgFoo) == nil)
	assert(msgBus.send(msgBar, 1) == 2)
end

local function multipleReducers()
	local msgBus = messageBus.new()
	local increaseDamageBy1 = function(msgType, msgValue)
		return msgValue + 1
	end
	msgBus.addReducer(increaseDamageBy1)
	msgBus.addReducer(increaseDamageBy1)

	local initialValue = 1
	local expectedValue = 3
	local handlerResult = nil
	local handler = function(msgType, finalDamage)
		handlerResult = finalDamage
	end
	local msgType = 'playerHit'
	msgBus.subscribe(handler)
	msgBus.send(msgType, initialValue)
	assert(handlerResult == expectedValue, 'expected '..expectedValue..' got '..tostring(handlerResult))
end

local function removeFunctions()
	local msgBus = messageBus.new()

	local reducerCallCount = 0
	local expectedReducerCallCount = 1
	local reducer = function(_, v)
		reducerCallCount = reducerCallCount + 1
		return msgBus.CLEANUP
	end
	msgBus.addReducer(reducer)

	local handlerCallCount = 0
	local expectedHandlerCallCount = 2
	local handler = function(msgType, finalValue)
		handlerCallCount = handlerCallCount + 1
		return msgBus.CLEANUP
	end
	local msgType = 'playerHit'
	msgBus.subscribe(handler)
	msgBus.send(msgType)
	msgBus.subscribe(handler)
	msgBus.send(msgType)

	assert(
		reducerCallCount == expectedReducerCallCount,
		'expected reducer call count to be '..expectedReducerCallCount..' got '..reducerCallCount
	)

	assert(
		handlerCallCount == expectedHandlerCallCount,
		'expected subscriber call count to be '..expectedHandlerCallCount..' got '..handlerCallCount
	)
end


local function perfTest()
	local msgBus = messageBus.new()

	local callCount = 0
	local function func(msgType, msgValue)
		callCount = callCount + 1
		if callCount % 2 == 0 then
			return msgBus.CLEANUP
		end
		return msgValue
	end

	local filterCount = 10000
	for i=1, filterCount do
		msgBus.addReducer(func)
	end

	local subscriberCount = 10000
	for i=1, subscriberCount do
		msgBus.subscribe(func)
	end

	local testSuite = function()
		local msg = {}
		local msgType = 'FOO'
		msgBus.send(msgType, msg)
	end

	perf({
		title = filterCount..' filters and '..subscriberCount..' subscribers',
		done = function(timeTaken, title)
			print(title, timeTaken)
		end
	})(testSuite)()
	print('callCount', callCount)
end

local function test()
	multipleReducers()
	removeFunctions()
	filteredListeners()
	-- perfTest()
end

test()