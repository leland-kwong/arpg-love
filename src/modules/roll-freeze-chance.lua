local seed = os.clock()
return function(percentOfMaxHealthDealt)
  seed = seed + 1
  math.randomseed(seed)
  local rollChance = 1/percentOfMaxHealthDealt
  return math.random(1, rollChance) == 1
end