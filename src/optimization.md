# Draw call killers

* switching between `love.graphics.draw` and primitive shape apis like `love.graphics.rectangle`, `love.graphics.circle`, etc... will trigger a new draw call on each switch.