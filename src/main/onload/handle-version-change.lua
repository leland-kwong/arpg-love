-- this is used for situations where certain versions need to reset all the saved games.
local function clearAllSavedStates()
  local Db = require 'modules.database'
  local F = require 'utils.functional'
  local db = Db.load('saved-states')
  F.forEach(F.keys(db:keyIterator()), function(key)
    db:delete(key)
      :next(function()
        print('file deleted')
      end)
  end)
end

return function()
  clearAllSavedStates()
end