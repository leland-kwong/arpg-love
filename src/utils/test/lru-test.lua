local LRU = require 'utils.lru'

local key1 = 'a'
local key2 = 'b'
local key3 = 'c'
local prunedValue = nil
local function pruneCallback(_, value)
  prunedValue = value
end
local lru = LRU.new(2, nil, pruneCallback)
lru:set(key1, 'foo')
lru:set(key2, 'bar')
lru:set(key3, 'baz')

assert(prunedValue == 'foo', "lru prune value mismatch")