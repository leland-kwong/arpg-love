local Cooldown = {}

function Cooldown:new(initialTime)
	local activeCooldowns = {
		_time = initialTime,
		_startTimeByKey = {},
		_durationByKey = {}
	}
	setmetatable(activeCooldowns, self)
	self.__index = self
	return activeCooldowns
end

function Cooldown:setGlobalTime(time)
	self._time = time
	return self
end

function Cooldown:set(key, duration)
	self._startTimeByKey[key] = self._time
	self._durationByKey[key] = duration
	return self
end

function Cooldown:isReady(key)
	local startTime = self._startTimeByKey[key]
	if startTime == nil then
		return true
	end
	local dt = self._time - startTime
	return dt >= self._durationByKey[key]
end

return Cooldown