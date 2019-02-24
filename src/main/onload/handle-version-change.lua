local Observable = require 'modules.observable'

local function clearNonDatabaseFolders()
  local function recursivelyDelete( item )
    if love.filesystem.getInfo( item , "directory" ) then
      for _, child in pairs( love.filesystem.getDirectoryItems( item )) do
        recursivelyDelete( item .. '/' .. child )
        love.filesystem.remove( item .. '/' .. child )
      end
    elseif love.filesystem.getInfo( item ) then
      love.filesystem.remove( item )
    end
    love.filesystem.remove( item )
  end

  local F = require 'utils.functional'
  local items = love.filesystem.getDirectoryItems('')
  local Db = require 'modules.database'
  local itemsToDelete = F.filter(items, function(item)
    local info = love.filesystem.getInfo(item)
    local realDir = love.filesystem.getRealDirectory(item)
    local isDatabaseDirectory = (item == Db.baseDir and info and info.type == 'directory')
    return (not isDatabaseDirectory)
      and string.find(realDir, 'AppData')
  end)
  F.forEach(itemsToDelete, function(item)
    recursivelyDelete(item)
  end)
end

local function clearDb(directory)
  local Db = require 'modules.database'
  local F = require 'utils.functional'
  local db = Db.load(directory)
  return Observable.all(
    F.map(
      F.keys(
        db:keyIterator()
      ),
      function(key)
        return db:delete(key)
      end
    )
  )
end

-- this is used for situations where certain versions need to reset all the saved games.
local function clearRootFolder()
  clearNonDatabaseFolders()
  return Observable.all(
    clearDb(''),
    clearDb('saved-states')
  )
end

return function()
  return clearRootFolder()
end
