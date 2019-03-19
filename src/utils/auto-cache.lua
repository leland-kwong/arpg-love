local AutoCache = {}

local Mt = {}
Mt.__index = Mt
Mt.__call = function(self, a)
	local val = self.cache:get(a)
  if (not val) then
		val = self.newValue(a)
		self.cache:set(a, val)
	end
	return val
end

function AutoCache.new(options)
	options.cache = options.cache or {
		set = function(self, k, v)
			self[k] = v
		end,
		get = function(self, k)
			return self[k]
		end
	}
	return setmetatable(options, Mt)
end

return AutoCache