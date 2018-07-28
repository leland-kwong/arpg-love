local function Enum(list)
	local enum = {}
	for k,v in pairs(list) do
		enum[v] = v
	end
	return enum
end

return Enum