local noop = require("utils.noop")
local objectUtils = require("utils.object-utils")

local defaultOptions = {
	onCacheHit = noop,
	resolver = function(lastArgs, input1, input2, input3)
		return (input1 ~= lastArgs[1]) or (input2 ~= lastArgs[2]) or (input3 ~= lastArgs[3])
	end
}

-- [table] options
-- [function] options.onCacheHit
local function memoize(fn, options)
	options = objectUtils.assign({}, defaultOptions, options)
	
	local shouldCurry = type(fn) == 'table'
	if shouldCurry then
		options = func
		return function(fn)
			return memoize(fn, options)
		end
	end

	local lastArgs = {nil, nil, nil}
	local out1 = nil
	local out2 = nil
	local out3 = nil
	local resolver = options.resolver
	local onCacheHit = options.onCacheHit

	return function(input1, input2, input3)
		local isNewInputs = resolver(lastArgs, input1, input2, input3)
		if not isNewInputs then
			onCacheHit(input1, input2, input3)
			return out1, out2, out3
		end
		lastArgs[1] = input1
		lastArgs[2] = input2
		lastArgs[3] = input3
		out1, out2, out3 = fn(input1, input2, input3)
		return out1, out2, out3
	end
end

return memoize