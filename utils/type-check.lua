local M = {}

local enabled = true

M.FUNCTION = 'function'
M.NUMBER = 'number'
M.THREAD = 'thread'
M.BOOL = 'boolean'
M.STRING = 'string'
M.TABLE = 'table'
M.NIL = 'nil'
M.USER_DATA = 'userdata'
M.NON_NIL = function(v)
	return v ~= nil, 'non_nil'
end

function M.validate(value, validType)
	if not enabled then
		return
	end

	local receivedType = type(value)
	local assertion = receivedType == validType

	-- evaluate valid type as a function
	if type(validType) == M.FUNCTION then
		assertion, errorMessage = validType(value)
		if errorMessage == nil then
			error("type validator should return both an assertion value and error message as a `string`")
		end
		if not assertion then
			error(errorMessage)
		end
	end
	--[[
		Assertion message will get evaluated regardless of whether it passes or not.
		To prevent unecessary string creations, we run it conditionally.
	]]
	if not assertion then
		local message = "value type `"..validType.."` expected, received value `"..tostring(value).."` of type `"..receivedType.."`."
		assert(assertion, message)
	end

	return assertion
end

function M.is(value, validType)
	if not enabled then
		return
	end

	return type(value) == validType
end

-- globally enables/disables type checking
function M.enable(enable)
	enabled = enable
end

return M