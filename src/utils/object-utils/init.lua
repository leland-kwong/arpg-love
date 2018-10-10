local Object = {}

local function apply(t1, t2)
	if t2 == nil then
		return t1
	end

	local isArrayLike = t2[1] ~= nil
	if isArrayLike then
		for i=1, #t2 do
			t1[i] = t2[i]
		end
	else
		for k,v in pairs(t2) do
			t1[k] = v
		end
	end
	return t1
end

--[[
Assigns key-value pairs by iterating over a series of objects.

Returns first input object
--]]
function Object.assign(t1, t2, t3, t4)
	t1 = t1 or {}
	apply(t1, t2)
	if t3 then
		apply(t1, t3)
	end
	if t4 then
		apply(t1, t4)
	end
	return t1
end

function Object.clone(t1)
	return Object.assign({}, t1)
end

function Object.deepCopy(t1)
	if (type(t1) ~= 'table') then
		return t1
	end

	local copy = {}
	for k,v in pairs(t1) do
		copy[k] = Object.deepCopy(v)
	end
	return copy
end

-- Does a shallow comparison of properties.
-- If changes exist we return a new copy with the changes merged into the source table
function Object.immutableApply(t1, t2)
	t1 = t1 or {}
	local copy = nil
	for k,v in pairs(t2) do
		local isNewValue = t1[k] ~= v
		if isNewValue then
			copy = copy or Object.clone(t1)
			copy[k] = v
		end
	end
	return copy or t1
end

Object.extend = Object.immutableApply

local readOnlyMetatable = {
	__newindex = function()
		error('table is read only')
	end
}
function Object.setReadOnly(o)
	local metatable = getmetatable(o)
	if not metatable then
		metatable = readOnlyMetatable
	else
		metatable.__newindex = readOnlyMetatable.__newindex
	end
	setmetatable(o, metatable)
	return o
end

return Object