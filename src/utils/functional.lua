local M = {}

function M.forEach(array, callback)
	for i=1, #array do
		local value = array[i]
		callback(value, i)
	end
end

function M.map(array, mapFn)
	local i = 0
	local list = {}
	for i=1, #array do
		local value = array[i]
		local mappedValue = mapFn(value, i)
		table.insert(list, mappedValue)
	end
	return list
end

function M.find(tbl, callback)
	local found = nil
	local i = 1
	while not found do
		found = callback(tbl[i], i)
		if not found then
			i = i + 1
		else
			return tbl[i]
		end
	end
	return nil
end

function M.filter(t, filterFn)
	local filteredList = {}
	for i=1, #t do
		local value = t[i]
		if (filterFn(value, i)) then
			table.insert(filteredList, value)
		end
	end
	return filteredList
end

function M.reduce(t, reducer, seed)
	local result = seed
	for i=1, #t do
		local v = t[i]
		result = reducer(result, v, i)
	end
	return result
end

function M.keys(_table)
	local keys = {}
	local i = 1
	for k,_ in pairs(_table) do
		keys[i] = k
		i = i + 1
	end
	return keys
end

-- takes in a series of functions and applies them to a function, returning a new function with all the functions applied to it.
function M.compose(...)
	local wrappers = {...}
	return function(func)
		local newFunc = func
		for i=1, #wrappers do
			newFunc = wrappers[i](newFunc)
		end
		return newFunc
	end
end

function M.wrap(fnToWrap, fn)
	local noop = require 'utils.noop'
	if (not fnToWrap) or (fnToWrap == noop) then
		return fn
	end
	return function(a, b, c, d, e, f, g)
		fnToWrap(a, b, c, d, e, f, g)
		return fn(a, b, c, d, e, f, g)
	end
end

return M