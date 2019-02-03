local dynamicRequire = require 'utils.dynamic-require'
local Vec2 = require 'modules.brinevector'
local Component = require 'modules.component'
local buildLevel = dynamicRequire 'components.hud.universe-map.build-level'
local Node = require 'utils.graph'.Node
local F = dynamicRequire 'utils.functional'
local Grid = dynamicRequire 'utils.grid'
local msgBus = require 'components.msg-bus'
local maps = require('modules.cargo').init('built/maps')

local getLevelDefinition = function(levelId)
  return maps[levelId]
end

return function(state)
  return {
    pan = function(dx, dy)
      state.initialTranslate = state.initialTranslate or state.translate
      state.translate = state.initialTranslate + Vec2(dx, dy)
    end,
    panEnd = function()
      state.initialTranslate = nil
    end,
    zoom = function(dz)
      local clamp = require 'utils.math'.clamp
      local round = require 'utils.math'.round
      Component.animate(state, {
        distScale = clamp(round(state.distScale + dz), 1, 2)
      }, 0.25, 'outCubic')
    end,
    nodeHoverIn = function(node)
      Component.animate(state.nodeStyles[node], {
        scale = 1.3
      }, 0.15, 'outQuint')
    end,
    nodeHoverOut = function(node)
      Component.animate(state.nodeStyles[node], {
        scale = 1
      }, 0.15, 'outQuint')
    end,
    nodeSelect = function(node)
      print('select', node)
    end,
    newGraph = function(model)
      state.nodeStyles = {}
      model:forEach(function(link)
        local node1, node2 = unpack(link)
        state.nodeStyles[node1] = {
          scale = 1
        }
        state.nodeStyles[node2] = {
          scale = 1
        }
      end)
    end,
    buildLevel = function(node, linkRefs)
      local nodeRef = Node:get('universe', node)
      local location = {
        layoutType = nodeRef.level
      }
      msgBus.send('PORTAL_ENTER', location)
      msgBus.send('MAP_TOGGLE')

      -- local ok, result = pcall(function()
      --   local nodeRef = Node:get('universe', node)
      --   local levelDefinition = getLevelDefinition(nodeRef.level)
      --   local seed = 1
      --   return {
      --     buildLevel(levelDefinition, node, state.graph:getLinksByNodeId(node, true), 1, 20)
      --   }
      -- end)
      -- if not ok then
      --   print(result)
      -- else
      --   state.levels = result
      -- end
    end
  }
end