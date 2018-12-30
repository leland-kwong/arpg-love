local dynamicRequire = require 'utils.dynamic-require'
-- local fs = dynamicRequire 'modules.file-system'
local Observable = dynamicRequire 'modules.observable'

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

local key = 'test-folder/test-file'

local Db = {}

local dbMt = {
  get = function(self, key)
    assert(key ~= nil, '[delete error] a key must be provided')
    self.index[key] = nil
    return self.data[key]
  end,
  put = function(self, key, value)
    assert(value ~= nil, '[put error] a value must be provided')
    return self:_saveToDisk(key, value)
      :next(function()
        self.data[key] = value
        self.index[key] = true
      end)
  end,
  delete = function(self, key)
    assert(key ~= nil, '[delete error] a key must be provided')
    return self:_saveToDisk(key)
      :next(function()
        self.data[key] = nil
        self.index[key] = nil
      end)
  end,
  _saveToDisk = function(self, a, b)
    return Observable(function()
      return true, true
    end)
  end
}
dbMt.__index = dbMt

local loadedDatabases = {}

function Db.load(directory)
  local db = loadedDatabases[directory] or setmetatable({
    -- hash table of the data stored where the key is the name of the file, and the value is the file's contents
    data = {},

    -- index of keys
    index = {},

    dir = directory,
  }, dbMt)
  loadedDatabases[directory] = db
  return db
end

local function testSuite(description, testFn)
  print('[test] ' .. description)
  testFn()
end

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
    db:put(key, value)
    db:delete(key)
      :next(function()
        if (db:get(key)) then
          print('delete did not remove the file')
        end
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
    end, function(err)
      print('scope error')
    end)
  end
)