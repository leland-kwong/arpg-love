return function()
  local fileSystem = require 'modules.file-system'
  local F = require 'utils.functional'
  local files = fileSystem.listSavedFiles('saved-states')
  F.forEach(files, function(fileData)
    fileSystem.deleteFile('saved-states', fileData.id)
      :next(function()
        print('file deleted')
      end)
  end)
end