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
	local listener3 = msgBus.on(msgBar, function(input)
		return input + 1
	end)

	assert(msgBus.send(msgFoo) == 1)
	assert(msgBus.send(msgBar, 1) == 2)

	msgBus.off(listener1)
	assert(msgBus.send(msgFoo) == nil)
	assert(msgBus.send(msgBar, 1) == 2)

	msgBus.off({listener3})
	assert(msgBus.send(msgBar) == nil)
end

local function listenersPriorityOrdering()
	local msgBus = messageBus.new()
	msgBus.on('foo', function(input)
		return input + 1
	end, 2)
	msgBus.on('foo', function()
		return 2
	end, 1)
	assert(msgBus.send('foo') == 3)
end

local function test()
	filteredListeners()
	listenersPriorityOrdering()
end

test()