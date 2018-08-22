-- Stateful utility library test --
local Stateful = require("utils.stateful")
local objectUtils = require("utils.object-utils")
local perf = require("utils.perf")
local tick = require'utils.tick'

local function createState(initialState, subscriber, options)
	options = objectUtils.assign({
		autoPersist = false,
	}, options)

	initialState = initialState or {
		foobar = 'bar'
	}

	local state = Stateful:new(initialState, options)
	state:subscribe(subscriber)
	return state
end

local state = createState()

-- basic stress testing to make sure its pretty fast under load
local randomNumbers = {}
for i=1, 500 do
	local number = math.random(0, 10000)
	table.insert(randomNumbers, number)
end
local setStatePerf = perf(function()
	for i=1, #randomNumbers do
		local num = randomNumbers[i]
		state:set("foobar", num)
	end
end, {
	maxTime = .2,
	title = 'setStatePerf',
})

local stateChangeCallbackTest = function()
	local called = nil
	local debounceRate = 0
	local state = createState({
		foobar = 'bar'
	}, function()
		called = true
	end, {
		debounceRate = debounceRate
	})
	state:set("foobar", 123)
	tick.delay(function()
		local errorMsg = "onStateChange callback should be called"
		assert(called == true, errorMsg)
	end, debounceRate)
end

local immutableStateTest = function()
	local initialState = {
		foobar = 'bar'
	}
	local options = {
		debounceRate = 0
	}
	local testState = createState(initialState, nil, options)

	testState:set("foobar", testState:get().foobar)
	local state, prevState = testState:get()
	local errorMsg = "unchanged states should be equal"
	assert(state == prevState, errorMsg)

	local testVal = 123
	testState:set("foobar", testVal)
	local state, prevState = testState:get()
	local newVal, oldVal = state.foobar, prevState.foobar
	local title = "[STATEFUL SET_STATE]"
	local errorMsg = title.." expected \""..testVal.." got \""..newVal.."\""
	assert(newVal == testVal, errorMsg)

	local errorMsg = "new val should not equal old val"
	assert(newVal ~= oldVal, errorMsg)

	assert(initialState ~= testState:get(), "initial state should be be mutated")
end

local constructorTest = function()
	local s1 = createState()
	local s2 = createState()
	local errorMsg = "state instances should not be equal"
	assert(s1 ~= s2, errorMsg)
end

local function unsubscribeTest()
	local s1 = createState({foo = 'blah'})
	local called = false
	local func = function()
		called = true
	end
	local token = s1:subscribe(func)
	s1:unsubscribe(token)
	s1:set('foo', 'bar', function()
		assert(not called, "[unsubscribe test] failed")
	end)
end

local function runTests()
	stateChangeCallbackTest()
	immutableStateTest()
	constructorTest()
	unsubscribeTest()

	-- perf --
	setStatePerf()
end

runTests()