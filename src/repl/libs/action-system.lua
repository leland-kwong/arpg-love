local ActionSystemMt = {
  createAction = function(self, actionType, handler)
    self.actionHandlers[actionType] = function(payload)
      local result = handler(payload)
      if self.onAction then
        self.onAction(actionType, payload, result)
      end
      return result
    end
    return self
  end,
  addActions = function(self, handlerDefinitions)
    for actionType,handler in pairs(handlerDefinitions) do
      self:createAction(actionType, handler)
    end
    return self
  end,
  send = function(self, actionType, payload)
    local actionHandler = self.actionHandlers[actionType]
    if (not actionHandler) then
      error('invalid action type '..actionType)
    end
    return actionHandler(payload)
  end
}
ActionSystemMt.__index = ActionSystemMt

return function(options)
  options = options or {}

  return setmetatable({
    onAction = options.onAction,
    actionHandlers = {}
  }, ActionSystemMt)
end