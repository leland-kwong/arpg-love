local O = require 'utils.object-utils'
local Observable = require 'modules.observable'

local stateDefaultOptions = {
  trackHistory = false,
  maxUndos = 100
}

return function(initialState, options)
  options = O.assign({}, stateDefaultOptions, options)

  local stateCopy = O.deepCopy(initialState)
  local stateMt = {
    _onChange = function()
      return self
    end,
    set = function(self, k, v, ignoreHistory)
      if self._setInProgress then
        error('[CreateState] Error setting property `' .. k .. '`. Cannot set the state while a set is already in progress.')
      end
      self._setInProgress = true

      local currentVal = self[k]
      local isNewVal = currentVal ~= v
      local shouldTrackChange = options.trackHistory and
        isNewVal and
        (not ignoreHistory) and
        (not self._logPending)
      if shouldTrackChange then
        self._logPending = true
        Observable(function()
          self._logPending = false
          self._changeHistory:push()
          return true
        end)
      end

      self[k] = v
      self._onChange(self, k, v, currentVal)

      self._setInProgress = false
      return self
    end,
    undo = function(self)
      local prevState = self._changeHistory:back() or {}
      for k,v in pairs(prevState) do
        self:set(k, v, true)
      end
    end,
    redo = function(self)
      local nextState = self._changeHistory:forward() or {}
      for k,v in pairs(nextState) do
        self:set(k, v, true)
      end
    end,
    onChange = function(self, callback)
      self._onChange = callback
      return self
    end,

    _setInProgress = false,
    _logPending = false,
    _changeHistory = {
      history = {},
      position = 0,
      removeEntriesAfterPosition = function(self, position)
        local i = #self.history
        while i > position do
          table.remove(self.history, i)
          i = i - 1
        end
      end,
      push = function(self)
        self:removeEntriesAfterPosition(self.position)

        local maxUndosReached = #self.history > options.maxUndos
        if maxUndosReached then
          table.remove(self.history, 1)
        end

        table.insert(self.history, O.clone(stateCopy))
        self.position = #self.history
      end,
      back = function(self)
        local clamp = require 'utils.math'.clamp
        self.position = clamp(self.position - 1, 0, #self.history)
        return self.history[self.position]
      end,
      forward = function(self)
        local clamp = require 'utils.math'.clamp
        self.position = clamp(self.position + 1, 0, #self.history)
        return self.history[self.position]
      end
    }
  }
  stateMt.__index = stateMt
  return setmetatable(stateCopy, stateMt)
end