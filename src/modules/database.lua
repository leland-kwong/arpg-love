local Observable = require 'modules.observable'
local F = require 'utils.functional'
local bitser = require 'modules.bitser'
local lru = require 'utils.lru'
local String = require 'utils.string'

local Db = {
  baseDir = 'db'
}

--[[ this is a global for live-reload reasons ]]
loadedDatabases = loadedDatabases or lru.new(300)

local Component = require 'modules.component'
Component.create({
  id = 'database-init',
  init = function(self)
    -- start async write thread
    local source = love.filesystem.read('modules/file-system/async-write.lua')
    self.thread = love.thread.newThread(source)
    self.thread:start()
  end,

  final = function(self)
    self.thread:release()
  end
})

local function diskIo(self, action, file, data)
  local fullPath = self.directory..'/'..file
  local serialized = data and bitser.dumps(data) or nil
  local message = bitser.dumps({
    action,
    fullPath,
    serialized,
  })
  love.thread.getChannel('DISK_IO')
    :push(message)
end

local function stringFilter(str, filter)
  if (type(filter) == 'string') then
    return string.find(str, filter)
  end
  return (not filter) or filter(str)
end

local function handleSaveAsync()
  local errorMsg = love.thread.getChannel('saveStateError'):pop()
  if errorMsg then
    return true, nil, errorMsg
  end

  local success = love.thread.getChannel('saveStateSuccess'):pop()
  if success then
    return true, true
  end
end

local function handleDeleteAsync()
  local errorMsg = love.thread.getChannel('saveStateDeleteError'):pop()
  if errorMsg then
    return true, nil, errorMsg
  end

  local success = love.thread.getChannel('saveStateDeleteSuccess'):pop()
  if success then
    return true, true
  end
end

local dbMt = {
  get = function(self, key)
    assert(key ~= nil, '[read error] a key must be provided')
    return self:_loadFile(key)
  end,

  put = function(self, key, value)
    assert(self.loaded, '[put error] database already destroyed')
    assert(value ~= nil, '[put error] a value must be provided')

    return self:_saveDataToDisk(key, value)
      :next(function(results)
        self.data[key] = value
        self.index[key] = true
        self:_incrementChangeCount()
        return results
      end)
  end,

  delete = function(self, key)
    assert(self.loaded, '[put error] database already destroyed')
    assert(key ~= nil, '[delete error] a key must be provided')

    return self:_deleteDataFromDisk(key)
      :next(function(results)
        self.data[key] = nil
        self.index[key] = nil
        self:_incrementChangeCount()
        return results
      end)
  end,

  readIterator = function(self, filter, includeData)
    if (includeData == nil) then
      includeData = true
    end

    return coroutine.wrap(function()
      for key in pairs(self.index) do
        if stringFilter(key, filter) then
          local contents, ok = includeData and self:get(key) or nil
          coroutine.yield(key, contents)
        end
      end
    end)
  end,

  keyIterator = function(self, filter)
    return self:readIterator(filter, false)
  end,

  -- removes all files from the folder and deletes the folder
  destroy = function(self)
    local deletes = {}
    for key in self:keyIterator() do
      table.insert(deletes, self:delete(key))
    end
    return Observable.all(deletes):next(function()
      local ok, err = pcall(function()
        local isRootDir = self.directory == ''
        if isRootDir then
          return true
        end
        return love.filesystem.remove(self.directory)
      end)
      if (not ok) then
        print(err)
      else
        self.loaded = false
        loadedDatabases:delete(self.directory)
      end
    end, function(err)
      print('[db destroy error]', err)
    end)
  end,

  _incrementChangeCount = function(self)
    self.changeCount = self.changeCount + 1
  end,

  _saveDataToDisk = function(self, key, value)
    diskIo(self, 'SAVE_STATE', String.escape(key), value)
    return Observable(handleSaveAsync)
  end,

  _deleteDataFromDisk = function(self, key)
    diskIo(self, 'SAVE_STATE_DELETE', String.escape(key))
    return Observable(handleDeleteAsync)
  end,

  _loadFile = function(self, key)
    local curValue = self.data[key]
    if curValue then
      return curValue
    end

    local path = self.directory..'/'..String.escape(key)
    local ok, result = pcall(function()
      return bitser.loads(
        bitser.loadLoveFile(path)
      )
    end)
    if (not ok) then
      return nil, result
    end
    self.data[key] = result
    return result
  end
}
dbMt.__index = dbMt

local function createDbDirectory(directory)
  local folderExists = love.filesystem.getInfo(directory)
  if (not folderExists) then
    love.filesystem.createDirectory(directory)
  end
end

local dirNameCache = {
  cache = lru.new(400),
  get = function(self, dir)
    dir = dir or ''
    local actualDir = self.cache:get(dir)
    if (not actualDir) then
      actualDir = Db.baseDir..'/'..dir
      self.cache:set(dir, actualDir)
    end
    return actualDir
  end
}

function Db.load(directory)
  local actualDir = dirNameCache:get(directory)

  assert(directory, '[db load error] directory must be a string')

  local dbRef = loadedDatabases:get(actualDir)
  if (not dbRef) then
    createDbDirectory(actualDir)
  end

  dbRef = dbRef or setmetatable({
    changeCount = 0,
    loaded = true,
    -- hash table of the data stored where the key is the name of the file, and the value is the file's contents
    data = {},

    -- index of keys
    index = F.reduce(
      love.filesystem.getDirectoryItems(actualDir),
      function(keyMap, file)
        local fullPath = actualDir..'/'..file
        local info = love.filesystem.getInfo(fullPath)
        if info and (info.type == 'file') then
          local originalKey = String.unescape(file)
          keyMap[originalKey] = true
        end
        return keyMap
      end,
      {}
    ),

    directory = actualDir
  }, dbMt)
  loadedDatabases:set(actualDir, dbRef)

  return dbRef
end

-- lists all databases for a given directory
function Db.databaseListIterator(directory, filter)
  local actualDir = dirNameCache:get(directory)
  local items = love.filesystem.getDirectoryItems(actualDir)
  local baseDirLength = #Db.baseDir

  return coroutine.wrap(function()
    for i=1, #items do
      local item = items[i]
      local fullPath = actualDir..'/'..item
      local info = love.filesystem.getInfo(fullPath)
      local isDir = info and (info.type == 'directory')
      if isDir and stringFilter(item, filter) then
        coroutine.yield(string.sub(fullPath, baseDirLength + 2))
      end
    end
  end)
end

return Db