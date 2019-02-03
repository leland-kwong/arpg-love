local M = {}

function M.forEach(array, callback, ctx)
	local len = array and #array or 0
	for i=1, len do
		local value = array[i]
		callback(value, i, ctx)
	end
end

function M.map(array, mapFn)
	local i = 0
	local list = {}
	for i=1, #(array or list) do
		local value = array[i]
		local mappedValue = mapFn(value, i)
		table.insert(list, mappedValue)
	end
	return list
end

local String = require 'utils.string'

local function getValueAtKeypath(obj, keypath)
  local pathList = String.split(keypath, '%.')
  local result = obj
  for i=1, #pathList do
    local key = pathList[i]
    result = result[key]
  end
  return result
end

M.getValueAtKeypath = getValueAtKeypath

function M.find(tbl, predicate, valueToMatch)
	local isKeypath = type(predicate) == 'string'
	local found = nil
	local i = 1
	local length = #tbl
	while (i <= length) and (not found) do
		local v = tbl[i]
		if isKeypath then
			found = getValueAtKeypath(v, predicate) == valueToMatch
		else
			found = predicate(v, i)
		end
		if not found then
			i = i + 1
		else
			return tbl[i]
		end
	end
	return nil
end

local function concatInsert(item, index, newList)
	table.insert(newList, item)
end

function M.concat(table1, table2)
	local newList = {}
	M.forEach(table1, concatInsert, newList)
	M.forEach(table2, concatInsert, newList)
	return newList
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
	if not t then
		return {}
	end
	local result = seed
	for i=1, #t do
		local v = t[i]
		result = reducer(result, v, i)
	end
	return result
end

function M.keys(iterable)
	local keys = {}
	local i = 1

	if (type(iterable) == 'table') then
		for k,_ in pairs(iterable) do
			keys[i] = k
			i = i + 1
		end
		return keys
	end

	for k,_ in iterable do
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
	return function(...)
		fnToWrap(...)
		return fn(...)
	end
end

return M