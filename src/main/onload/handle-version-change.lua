local Observable = require 'modules.observable'
-- this is used for situations where certain versions need to reset all the saved games.
local function clearAllSavedStates()
  local Db = require 'modules.database'
  local F = require 'utils.functional'
  local db = Db.load('saved-states')
  Observable.all(
    F.map(F.keys(db:keyIterator()), function(key)
      return db:delete(key)
    end)
  ):next(function()
    print('all files deleted')
  end, function(err)
    print('[clear all files error]', err)
  end)
end

return function()
  clearAllSavedStates()
end