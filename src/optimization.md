# Optimization notes

## Operations that trigger a new draw call

Whenever these operations are alternated, a new draw call is triggered. To get around this, drawing operations should be grouped together by their operation type.

Operation types are:

- `love.graphics.draw` with `love.graphics.newImage`
- `love.graphics.draw` with `love.graphics.newText`
- primitive shapes including: `love.graphics.line`, `love.graphics.rectangle`, `love.graphics.circle`, etc...
- `love.graphics.print`
- `love.graphics.draw` with `love.graphics.newMesh`

## Batch text drawing by using a single `newText` object

Love's [`Text`](https://love2d.org/wiki/Text) object allows you to add additional colored text nodes to it. This means we can add multiple strings to the object and then do a single `love.graphics.draw(MyTextObject)` call.