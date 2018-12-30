local dynamicRequire = require 'utils.dynamic-require'
local fs = dynamicRequire 'modules.file-system'
local Observable = dynamicRequire 'modules.observable'
local F = require 'utils.functional'
local bitser = require 'modules.bitser'

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
      :next(function()
        self.data[key] = value
        self.index[key] = true
      end)
  end,

  delete = function(self, key)
    assert(self.loaded, '[put error] database already destroyed')
    assert(key ~= nil, '[delete error] a key must be provided')

    return self:_deleteDataFromDisk(key)
      :next(function()
        self.data[key] = nil
        self.index[key] = nil
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
    return Observable(function()
      local ok, result = pcall(function()
        local path = self.directory..'/'..key
        bitser.dumpLoveFile(path, value)
      end)
      return true, ok, result
    end)
  end,

  _deleteDataFromDisk = function(self, key)
    return Observable(function()
      local ok, result = pcall(function()
        local path = self.directory..'/'..key
        return love.filesystem.remove(path)
      end)

      local err = (not ok) and 'error deleting file '..key or nil
      return true, ok, err
    end)
  end,

  _loadFile = function(self, key)
    local curValue = self.data[key]
    if curValue then
      return curValue
    end

    local path = self.directory..'/'..key
    local ok, result = pcall(function()
      return bitser.loadLoveFile(path)
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

local function testSuite(description, testFn)
  print('[test] ' .. description)
  testFn()
end

testSuite(
  'read iterator',
  function()
    local db = Db.load('iterator-test')
    local puts = {}

    local function tableEqual(t1, t2)
      for k,v in pairs(t1) do
        if (t2[k] ~= v) then
          return false
        end
      end
      return true
    end

    local data = {
      ['gameId_data'] = math.random(),
      ['gameId_metadata'] = math.random(),
      ['gameId_skill-tree-data'] = math.random(),
      ['gameId2_skill-tree-data'] = math.random()
    }
    for k,v in pairs(data) do
      table.insert(puts, db:put(k, v))
    end

    Observable.all(puts)
      :next(function()
        local iter = db:readIterator()
        local savedData = {}
        for key,value in iter do
          savedData[key] = value
        end
        assert(tableEqual(data, savedData), 'iterator read incorrect')

        db:destroy()
      end, function(err)
        print(err)
      end)
      :next(nil, function(err)
        print(err)
      end)
  end
)

testSuite(
  'file save',
  function()
    local db = Db.load('file-save-test')
    local key,value = 'foo', 'bar'
    db:put(key, value)
      :next(function()
        local result = db:get(key)
        if (result ~= value) then
          print('put error')
        end
        db:destroy()
      end, function(err)
        print(err)
      end)
  end
)

testSuite(
  'file delete',
  function()
    local db = Db.load('file-delete-test')
    local key, value = 'foo', 'bar'
    db:put(key, value):next(function()
      db:delete(key)
        :next(function()
          if (db:get(key)) then
            print('delete did not remove the file')
          end
          db:destroy()
        end)
    end, function(err)
      print(err)
    end)
  end
)

testSuite(
  'database operations are scoped to directory',
  function()
    local db1 = Db.load('db-scope-1')
    local db2 = Db.load('db-scope-2')
    local key = 'foo'
    Observable.all({
      db1:put(key, 'foo1'),
      db2:put(key, 'foo2')
    }):next(function()
      local save1, save2 = db1:get(key), db2:get(key)
      local success = save1 and save2 and save1 ~= save2
      if (not success) then
        print('[ERROR] db operations are not scoped properly')
      end
      db1:destroy()
      db2:destroy()
    end, function(err)
      print('scope error')
    end)
  end
)

testSuite(
  'destroy database',
  function()
    local db = Db.load('db-destroy-test')
    db:put('foo', 'bar')
      :next(function()
        db:destroy():next(function()
          local folderExists = love.filesystem.getInfo(db.directory)
          assert(not folderExists, 'directory should be destroyed')
        end, function(err)
          print(err)
        end)
        :next(nil, function(err)
          print(err)
        end)
      end, function(err)
        print(err)
      end)
  end
)