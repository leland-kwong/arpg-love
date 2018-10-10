local socket = require 'socket'
local bitser = require 'modules.bitser'

local function gettime()
  return socket.gettime() * 1000
end

local function runTest(fs, saveState)
  local rootPath = 'unit-test-save-root-path'
  local saveId = 'unit-test-save'

  local function saveSuccess()
    print('save success')
    local saveList = fs.listSavedFiles(rootPath)
    assert(type(saveList) == 'table', 'save list should be a table')
    assert(#saveList == 1, 'save list should be 1 file')

    local save = saveList[1]
    assert(type(save.id) == 'string', 'save id should be of type `string`')
    assert(type(save.metadata) == 'table', 'save metadata should be of type `table`')

    local savedState = fs.loadSaveFile(rootPath, save.id)
    assert(type(savedState) == 'table')

    return fs.deleteFile(rootPath, save.id)
      :next(function()
        print('delete success')
      end, function(err)
        print(err)
      end)
  end

  local function saveError(err)
    error(err)
  end

  fs.saveFile(rootPath, saveId, saveState, { displayName = saveState.displayName })
    :next(saveSuccess, saveError)
    :next(nil, function(err)
      print(err)
    end)
end

local tick = require 'utils.tick'

return function(fs)
  print('[TEST] file-system')

  local tick = require 'utils.tick'

  local saveState = {
    displayName = 123,
    foo = 'foo',
    unitTest = true,
    largeList = {}
  }
  for i=1, 10 do
    table.insert(saveState.largeList, 'lorem ipsum dolor'..i)
  end

  local function save()
    runTest(fs, saveState)
  end
  save()

end