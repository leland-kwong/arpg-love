local socket = require 'socket'
local objectUtils = require("utils.object-utils")

local getTime = socket.gettime

local defaultOptions = {
	-- if execution time exceeds this time, we'll throw a warning
	maxTime = 99999999999999999,
	title = '',
	enabled = true,
	done = function()
	end
}
-- profiler function to measure the performance cost to run the provided function
local function perf(func, options)
	options = objectUtils.assign({}, defaultOptions, options)

	if not options.enabled then
		return func
	end

	local shouldCurry = type(func) == 'table'
	if shouldCurry then
		options = func
		return function(func)
			return perf(func, options)
		end
	end

	local callCount = 0
	local totalExecutionTime = 0
	return function(a, b, c, d, e, f, g, h)
		local ts = getTime()

		local out1, out2, out3 = func(a, b, c, d, e, f, g, h)

		local executionTimeMs = (getTime() - ts) * 1000
		totalExecutionTime = totalExecutionTime + executionTimeMs
		callCount = callCount + 1

		local maxTime = options.maxTime
		local title = options.title
		if maxTime < executionTimeMs then
			local prefix = #title > 0 and '['..title..']' or ''
			print('[PERF WARNING]'..prefix..' - '..executionTimeMs..'(ms) exceeds maxAvgTime of '..maxTime..'(ms)')
		end
		options.done(executionTimeMs, totalExecutionTime, callCount, a, b, c, d, e, f, g, h)

		return out1, out2, out3
	end
end

return perf