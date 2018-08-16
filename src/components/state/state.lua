--[[

Main game state

**
NOTE:
Time sensitive game states should not rely on the state in this module.
The updates may occur asynchronously, which could throw off timing. Currently
this is mainly for keeping the gui updated with the state of the game.
**

Everything from game configuration options to game data is stored, saved, and
retrieved in this module.

]]--

local Stateful = require("utils.stateful")
local config = require('config')
local sc = require("components.state.constants")
local itemConfig = require("components.item-inventory.items.config")
local baseStatModifiers = require("components.state.base-stat-modifiers")

local EMPTY_SLOT = sc.inventory.EMPTY_SLOT

local base = 4
local levelExperienceRequirements = {
	base * 1,
	base * 2,
	base * 3.5,
	base * 6,
	base * 9,
	base * 14,
	base * 20,
	base * 300,
	base * 1000,
}

-- NOTE: This state is immutable, so we should keep the structure as flat as possible to avoid deep updates
local initialState = {
	level = 1,
	exp = 0,
	totalExp = 0,
	expToNextLevel = levelExperienceRequirements[1],
	enemyKillCount = 0,

	--[[ base player stats ]]
	health = 200,
	maxHealth = 200,

	--[[ static modifiers ]]
	statModifiers = baseStatModifiers(),

	--[[ buffs, debuffs, auras, ailments ]]
	statusEffects = {},

	inventory = require'utils.make-grid'(11, 9, EMPTY_SLOT),

	--[[ equipped items ]]
	equipment = require'utils.functional'.reduce(
		require'utils.functional'.keys(itemConfig.equipmentGuiRenderNodeMap),
		function(categories, cat)
			categories[cat] = EMPTY_SLOT
			return categories
		end,
		{}
	),

	--[[ game settings ]]
	music = false,
	-- curently active menu panel
	activeMenu = false,
}

local function createStore(options)
	return Stateful:new(
		initialState,
		options
	)
end

return createStore