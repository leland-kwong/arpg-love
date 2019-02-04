local Object = {}

local function apply(t1, t2, deep)
	if t2 == nil then
		return t1
	end

	if type(t2) ~= 'table' then
		return t2
	end

	local isArrayLike = t2[1] ~= nil
	if isArrayLike then
		for i=1, #t2 do
			if deep then
				t1[i] = apply(t1[i], t2[i], deep)
			else
				t1[i] = t2[i]
			end
		end
	else
		for k,v in pairs(t2) do
			if deep then
				t1[k] = apply(t1[k], v, deep)
			else
				t1[k] = v
			end
		end
	end
	return t1
end

--[[
Assigns key-value pairs by iterating over a series of objects.

Returns first input object
--]]
function Object.assign(t1, t2, t3, t4, deep)
	t1 = t1 or {}
	apply(t1, t2, deep)
	if t3 then
		apply(t1, t3, deep)
	end
	if t4 then
		apply(t1, t4, deep)
	end
	return t1
end

function Object.clone(t1)
	return Object.assign({}, t1)
end

function Object.deepCopy(t1, fromRecursion)
	if (type(t1) ~= 'table') then
		if (not fromRecursion) then
			return t1 == nil and {} or t1
		end
		return t1
	end

	local copy = {}
	for k,v in pairs(t1) do
		copy[k] = Object.deepCopy(v, true)
	end
	return copy
end

function Object.deepEqual(t1, t2)
	if (not t1) or (not t2) then
		return false
	end

	for k,v in pairs(t1) do
		if (type(v) == 'table') then
			if not Object.deepEqual(v, t2[k]) then
				return false
			end
		else
			if (t2[k] ~= v) then
				return false
			end
		end
  end
  return true
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
	__readOnly = true,
	__emptyObject = true,
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

function Object.isEmpty(t)
	for _ in pairs(t) do
    return false
  end
  return true
end

Object.EMPTY = Object.setReadOnly({})

return Object