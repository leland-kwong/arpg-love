local stateById = {}

-- automatically returns a new state if one does not exist
-- if the status is done, then we'll also create a new state
function stateById:get(id)
	local state = self[id]
	if not state or state.done then
		state = {}
	end
	self[id] = state
	return state
end

-- marks state as done and removes the reference to it
function stateById:done(id)
	local state = self:get(id)
	state.done = true
	-- remove table reference
	self[id] = nil
	return state
end

return stateById