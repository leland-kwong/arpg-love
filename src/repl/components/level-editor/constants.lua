local Enum = require 'utils.enum'

local editorModes = Enum(
  'SELECT',
  'ERASE',
  'PLACE'
)

return {
  editorModes = editorModes
}