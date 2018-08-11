--[[ source: http://yonaba.github.io/Jumper/ ]]--

-- modules have to be explicitly required because defold statically
-- analyzes requires during build
local rootPath = "modules.jumper."
require(rootPath.."search.jps")
require(rootPath.."search.dfs")
require(rootPath.."search.bfs")
require(rootPath.."search.thetastar")
require(rootPath.."search.dijkstra")
require(rootPath.."search.astar")
require(rootPath.."core.bheap")
require(rootPath.."core.assert")
require(rootPath.."core.node")
require(rootPath.."core.path")
require(rootPath.."core.utils")

Grid = require(rootPath.."grid") -- The grid class
Pathfinder = require (rootPath.."pathfinder") -- The pathfinder class
local Heuristics = require(rootPath.."core.heuristics")

return {
	Heuristics = Heuristics
}