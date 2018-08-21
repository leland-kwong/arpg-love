--[[
simple logger that automatically removes older entries based on a size limit
]]--

local logger = {}

function logger:new(size)
	local o = {
		entries = {},
		size = size or 5,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function logger:add(entry)
	-- insert to front of list
	table.insert(self.entries, 1, entry)
	-- remove oldest entry
	if #self.entries > self.size then
		self.entries[#self.entries] = nil
	end
end

function logger:get()
	return self.entries
end

return logger