local dynamic = require 'utils.dynamic-require'
local mdToLove2d = dynamic 'modules.markdown-to-love2d-string'

local text = '* Reduce movement speed of mock shoes from *40* to **10**.'
print(
  mdToLove2d(text).plainText
)