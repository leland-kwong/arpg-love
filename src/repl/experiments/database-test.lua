local dynamicRequire = require 'utils.dynamic-require'
local Db = dynamicRequire 'modules.database'
local Observable = dynamicRequire 'modules.observable'

local function tableEqual(t1, t2)
  for k,v in pairs(t1) do
    if (t2[k] ~= v) then
      return false
    end
  end
  return true
end

local enabled = false
local function testSuite(description, testFn)
  -- print('[test] ' .. description)
  if enabled then
    testFn()
  end
end

testSuite(
  'save with escaped keys',
  function()
    local dbPath = 'test/db-escape-key-test'
    local db = Db.load(dbPath)

    local function handleError(err)
      print('[escape key test]', err)
    end
    local key, val = 'item-2/data', 'foo'
    --[[
      normally special characters like "/" are not allowed for file names, so by escaping all keys, we can
      use any character for our keys
    ]]
    db:put(key, val)
      :next(function()
        local String = require 'utils.string'
        local fullPath = db.directory..'/'..String.escape(key)
        assert(
          love.filesystem.read(fullPath) ~= nil,
          'file not saved with escaped key'
        )
        assert(db:get('item-2/data') ~= nil, 'escaped key not working for [get]')
        local F = require 'utils.functional'
        assert(
          #F.keys(db:keyIterator()) == 1,
          'escaped key not working for [keyIterator]'
        )
        db:destroy()
      end, handleError)
      :next(nil, handleError)
  end
)

testSuite(
  'file save',
  function()
    local key,value = 'foo', 'bar'

    local db1 = Db.load('file-save-test')
    db1:put(key, value)
      :next(function()
        local result = db1:get(key)
        if (result ~= value) then
          print('put error')
        end
        db1:destroy()
      end,
      function(err)
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
  'read iterator',
  function()
    local db = Db.load('iterator-test')
    local puts = {}

    local data = {
      ['gameId_data'] = math.random(),
      ['gameId_metadata'] = math.random(),
      ['gameId_skill-tree-data'] = math.random(),
      ['gameId2_skill-tree-data'] = math.random()
    }
    local k = 'gameId2_skill-tree-data'
    local filteredData = {
      [k] = data[k]
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

        local filteredSavedData = {}
        local iter = db:readIterator('gameId2')
        for k,v in iter do
          filteredSavedData[k] = v
        end
        assert(tableEqual(filteredData, filteredSavedData), 'filtered iterator incorrect')

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

testSuite(
  'store file at root level (no folder)',
  function()
    local db = Db.load('')
    local key, val = 'root-level-file', 'foo'
    db:put(key, val)
      :next(function()
        assert(
          db:get(key) == val,
          '[db-root-level-error] root level file storage failed'
        )
        db:delete(key)
      end, function(err)
        print('[db-root-level-error]', err)
      end)
  end
)

testSuite('list databases', function()
  local rootDb = Db.load('test/list-test')
  local dbPaths = {
    ['test/list-test/db-1'] = true,
    ['test/list-test/db-2'] = true
  }
  for path in pairs(dbPaths) do
    Db.load(path)
  end

  local function handleError(err)
    print('[db list test error]', err)
  end
  rootDb:put('foo', 'bar')
    :next(function()
      local dbListIterator = Db.databaseListIterator('test/list-test')
      local dbList = {}
      for dbPath in dbListIterator do
        dbList[dbPath] = true
      end
      assert(
        tableEqual(dbPaths, dbList),
        'incorrect db list'
      )
    end, handleError)
    :next(nil, handleError)
end)

-- local Component = require 'modules.component'
-- Component.create({
--   id = 'database-perf-test',
--   init = function(self)
--     Component.addToGroup(self, 'gui')
--     self.clock = 0
--   end,
--   draw = function(self)
--     love.graphics.push()
--     love.graphics.origin()
--     love.graphics.translate(400, 100)

--     love.graphics.setColor(0,0,0,0.4)
--     love.graphics.rectangle('fill', 0, 0, 100, 400)
--     love.graphics.setColor(1,1,1)
--     local db = Db.load('saved-states')
--     local F = require 'utils.functional'
--     love.graphics.print(
--       Inspect(
--         F.keys(db:keyIterator())
--       )
--     )

--     love.graphics.pop()
--   end
-- })