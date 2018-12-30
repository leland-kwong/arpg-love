local dynamicRequire = require 'utils.dynamic-require'
local Db = dynamicRequire 'modules.database'
local Observable = dynamicRequire 'modules.observable'

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

local Component = require 'modules.component'
Component.create({
  id = 'database-perf-test',
  init = function(self)
    Component.addToGroup(self, 'all')
    self.clock = 0

    self.bigData = {}
    for i=1, 550 do
      self.bigData[i .. 'a'] = math.random() .. math.random()
    end
  end,
  update = function(self, dt)
    self.angle = self.angle + dt * 4
    self.clock = self.clock + 1

    local db = Db.load('db-perf')
    db:put('metadata', {
      timestamp = os.clock(),
      bigData = self.bigData
    })
  end,
  draw = function(self)
    love.graphics.clear()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.translate(400, 100)

    local db = Db.load('db-perf')
    local metadata = db:get('metadata') or {}
    love.graphics.print(metadata.timestamp or '', 0, 100)

    love.graphics.rotate(self.angle)
    love.graphics.setColor(1,1,0)
    local size = 50
    local offset = -size/2
    love.graphics.rectangle('fill', offset, offset, size, size)
    love.graphics.pop()
  end
})