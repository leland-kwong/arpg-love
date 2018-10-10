local f = require 'utils.functional'
local bitser = require 'modules.bitser'
local config = require 'config.config'
local lru = require 'utils.lru'

local fileSystem = {}

local function saveSavedGamesList()
  bitser.dumpLoveFile(SAVED_GAMES_LIST, savedGames)
end

local bitser = require 'modules.bitser'

local saveRootPath = 'saved-states/'

local function getSavedStatePath(saveId)
  return saveRootPath..saveId..'/save-state.save'
end

local function getMetadataPath(saveId)
  return saveRootPath..saveId..'/metadata.dat'
end

local readCache = lru.new(100)

function fileSystem.saveFile(saveId, data, metadata)
  local folderExists = readCache:get(saveId)
  if (not folderExists) then
    readCache:set(saveId, true)
    love.filesystem.createDirectory(saveRootPath..saveId)
  end
  bitser.dumpLoveFile(getMetadataPath(saveId), metadata)
  bitser.dumpLoveFile(
    getSavedStatePath(saveId),
    data
  )
end

function fileSystem.loadSaveFile(saveId)
  local errorFree, loadedState = pcall(function()
    return bitser.loadLoveFile(getSavedStatePath(saveId))
  end)
  return loadedState
end

function fileSystem.deleteSaveFile(saveId)
  love.filesystem.remove(saveId)
end

function fileSystem.listSavedFiles()
  local saves = love.filesystem.getDirectoryItems(saveRootPath)
  return f.map(saves, function(saveId)
    return {
      id = saveId,
      metadata = bitser.loadLoveFile(getMetadataPath(saveId))
    }
  end)
end

if config.isDebug then
  require 'modules.file-system.test'(fileSystem)
end

return fileSystem