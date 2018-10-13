local noop = require("utils.noop")
local objectUtils = require("utils.object-utils")

local defaultOptions = {
	resolver = function(lastArgs, input1, input2, input3, input4)
		return (input1 ~= lastArgs[1])
			or (input2 ~= lastArgs[2])
			or (input3 ~= lastArgs[3])
			or (input4 ~= lastArgs[4])
	end
}

-- [table] options
-- [function] options.resolver
local function memoize(fn, options)
	options = objectUtils.assign({}, defaultOptions, options)

	local shouldCurry = type(fn) == 'table'
	if shouldCurry then
		options = func
		return function(fn)
			return memoize(fn, options)
		end
	end

	local lastArgs = {nil, nil, nil, nil}
	local out1 = nil
	local out2 = nil
	local out3 = nil
	local out4 = nil
	local resolver = options.resolver

	return function(input1, input2, input3, input4)
		local isNewInputs = resolver(lastArgs, input1, input2, input3, input4)
		if isNewInputs then
			lastArgs[1] = input1
			lastArgs[2] = input2
			lastArgs[3] = input3
			lastArgs[4] = input4
			out1, out2, out3, out4 = fn(input1, input2, input3, input4)
		end
		return out1, out2, out3, out4
	end
end

return memoize