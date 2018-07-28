const fs = require('fs')

const inputConfig = fs.readFileSync('../../input/game.input_binding', 'utf8')
const inputs = inputConfig.match(/action\: [a-z0-9_\"]*\n/g)
  .map(str => str.slice(9, -2))
const luaCodeString = `
local bindings = {
${
  inputs
    .map(inputName => {
      return `\t${inputName} = '${inputName}'`
    })
    .join(',\n')
}
}

local hashedInputs = {
${
  inputs
    .map(input => `\t${input.toUpperCase()} = hash('${input}')`)
    .join(',\n')
}
}

return {
  bindings = bindings, 
  hashed = hashedInputs
}
`.trim()
fs.writeFileSync('./input-binding-defaults.lua', luaCodeString)