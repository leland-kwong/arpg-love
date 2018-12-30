local dynamicRequire = require 'utils.dynamic-require'
local Observable = dynamicRequire 'modules.observable'
local F = require 'utils.functional'
local bitser = require 'modules.bitser'

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
    action = action,
    payload = {
      fullPath,
      serialized
    }
  })
  love.thread.getChannel('DISK_IO')
    :push(message)
end

-- split a string
function splitString(str, delimiter)
  local result = { }
  local from  = 1
  local delim_from, delim_to = string.find( str, delimiter, from  )
  while delim_from do
    table.insert( result, string.sub( str, from , delim_from-1 ) )
    from  = delim_to + 1
    delim_from, delim_to = string.find( str, delimiter, from  )
  end
  table.insert( result, string.sub( str, from  ) )
  return result
end

local Db = {}

local loadedDatabases = {}

local defaultKeyFilter = function()
  return true
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
        return results
      end)
  end,

  readIterator = function(self, filter, includeData)
    if (type(filter) == 'string') then
      local pattern = string.gsub(filter, '%-', '%%-')
      filter = function(str)
        return string.find(str, pattern) ~= nil
      end
    end
    filter = filter or defaultKeyFilter

    if (includeData == nil) then
      includeData = true
    end

    return coroutine.wrap(function()
      for key in pairs(self.index) do
        if filter(key) then
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
        return love.filesystem.remove(self.directory)
      end)
      if (not ok) then
        error(err)
      else
        self.loaded = false
      end
    end, function(err)
      print('[db destroy error]', err)
    end)
  end,

  _saveDataToDisk = function(self, key, value)
    diskIo(self, 'SAVE_STATE', key, value)

    return Observable(function()
      local errorMsg = love.thread.getChannel('saveStateError'):pop()
      if errorMsg then
        return true, nil, errorMsg
      end

      local success = love.thread.getChannel('saveStateSuccess'):pop()
      if success then
        return true, true
      end
    end)
  end,

  _deleteDataFromDisk = function(self, key)
    diskIo(self, 'SAVE_STATE_DELETE', key)

    return Observable(function()
      local errorMsg = love.thread.getChannel('saveStateDeleteError'):pop()
      if errorMsg then
        return true, nil, errorMsg
      end

      local success = love.thread.getChannel('saveStateDeleteSuccess'):pop()
      if success then
        return true, true
      end
    end)
  end,

  _loadFile = function(self, key)
    local curValue = self.data[key]
    if curValue then
      return curValue
    end

    local path = self.directory..'/'..key
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

function Db.load(directory)
  local db = loadedDatabases[directory]
  if (not db) then
    createDbDirectory(directory)
  end
  db = db or setmetatable({
    loaded = true,
    -- hash table of the data stored where the key is the name of the file, and the value is the file's contents
    data = {},

    -- index of keys
    index = F.reduce(
      love.filesystem.getDirectoryItems(directory),
      function(filesMap, file)
        filesMap[file] = true
        return filesMap
      end,
      {}
    ),

    directory = directory,
    keyParser = function(str)
      return splitString(str, '/')
    end
  }, dbMt)

  loadedDatabases[directory] = db
  return db
end

return Db