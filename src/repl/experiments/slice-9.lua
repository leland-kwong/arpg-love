local Component = require 'modules.component'
local json = require 'lua_modules.json'
local dynamic = require 'utils.dynamic-require'
local AnimationFactory = dynamic 'components.animation-factory'

local function setupSlice9(spriteName)
  local guiSpriteData = json.decode(
    love.filesystem.read('built/sprite-gui.json')
  )
  local F = require 'utils.functional'
  local guiSpriteData = F.reduce(guiSpriteData.meta.slices, function(data, slice)
    data[slice.name] = slice
    return data
  end, {})
  local padding = 2 -- sprite sheet padding

  local slice9Data = guiSpriteData[spriteName].keys[1]

  local slice1 = AnimationFactory:new({'gui-'..spriteName})

  local function setupSlice(x2, y2, width, height, ox, oy)
    ox = ox or 0
    oy = oy or 0

    local padding = 2
    local slice = AnimationFactory:new({'gui-'..spriteName})
    local x, y = slice.sprite:getViewport()
    slice.sprite:setViewport(
      x + padding + x2,
      y + padding + y2,
      width,
      height
    )
    return {
      graphic = slice,
      ox = x2 - padding,
      oy = y2 - padding,
    }
  end

  print(
    Inspect(slice9Data)
  )

  return {
    scaleFactor = {
      w = slice9Data.center.w,
      h = slice9Data.center.h
    },
    slices = {
      [1] = setupSlice(
        0,
        0,
        slice9Data.center.x,
        slice9Data.center.y
      ),
      [2] = setupSlice(
        slice9Data.center.x,
        0,
        slice9Data.center.w,
        slice9Data.center.y
      ),
      [3] = setupSlice(
        slice9Data.center.x + slice9Data.center.w,
        0,
        slice9Data.bounds.w - (slice9Data.center.x + slice9Data.center.w),
        slice9Data.center.y
      ),
      [4] = setupSlice(
        0,
        slice9Data.center.y,
        slice9Data.center.x,
        slice9Data.center.h
      ),
      [5] = setupSlice(
        slice9Data.center.x,
        slice9Data.center.y,
        slice9Data.center.w,
        slice9Data.center.h
      ),
      [6] = setupSlice(
        slice9Data.center.x + slice9Data.center.w,
        slice9Data.center.y,
        slice9Data.bounds.w - (slice9Data.center.x + slice9Data.center.w),
        slice9Data.center.h
      ),
      [7] = setupSlice(
        0,
        slice9Data.center.y + slice9Data.center.h,
        slice9Data.bounds.w - (slice9Data.center.x + slice9Data.center.w),
        slice9Data.bounds.h - (slice9Data.center.y + slice9Data.center.h)
      ),
      [8] = setupSlice(
        slice9Data.center.x,
        slice9Data.center.y + slice9Data.center.h,
        slice9Data.center.w,
        slice9Data.bounds.h - (slice9Data.center.y + slice9Data.center.h)
      ),
      [9] = setupSlice(
        slice9Data.center.x + slice9Data.center.w,
        slice9Data.center.y + slice9Data.center.h,
        slice9Data.bounds.w - (slice9Data.center.x + slice9Data.center.w),
        slice9Data.bounds.h - (slice9Data.center.y + slice9Data.center.h)
      )
    }
  }
end

local menuPanelGraphics = setupSlice9('panel-menu')

local function slice9(box)
  local p = 2 -- padding

  love.graphics.setColor(1,1,1)

  local s1 = menuPanelGraphics.slices[1]
  local s3 = menuPanelGraphics.slices[3]
  local s7 = menuPanelGraphics.slices[7]

  local slice1W, slice1H = select(3, s1.graphic.sprite:getViewport())
  local slice3W, slice3H = select(3, s3.graphic.sprite:getViewport())
  local slice7W, slice7H = select(3, s7.graphic.sprite:getViewport())
  local sf = menuPanelGraphics.scaleFactor
  local cornersWidth = slice1W + slice3W
  local cornersHeight = slice1H + slice7H
  local actualWidth = math.max(0, box.w - cornersWidth)
  local actualHeight = math.max(0, box.h - cornersHeight)
  local w,h = actualWidth/sf.w, actualHeight/sf.h
  local x, y = box.x + p, box.y + p

  local xRight = x - p + slice1W + actualWidth
  local yBottom = y - p + slice1H + actualHeight

  s1.graphic:draw(x + s1.ox, y + s1.oy, 0, 1, 1, 0, 0)

  local s2 = menuPanelGraphics.slices[2]
  s2.graphic:draw(x + s2.ox, y + s2.oy, 0, w, 1, 0, 0)

  s3.graphic:draw(xRight, y + s3.oy, 0, 1, 1, 0, 0)

  local s4 = menuPanelGraphics.slices[4]
  s4.graphic:draw(x + s4.ox, y + s4.oy, 0, 1, h, 0, 0)

  local s5 = menuPanelGraphics.slices[5]
  s5.graphic:draw(x + s5.ox, y + s5.oy, 0, w, h, 0, 0)

  local s6 = menuPanelGraphics.slices[6]
  s6.graphic:draw(xRight, y + s6.oy, 0, 1, h, 0, 0)

  s7.graphic:draw(x + s7.ox, yBottom, 0, 1, 1, 0, 0)

  local s8 = menuPanelGraphics.slices[8]
  s8.graphic:draw(x + s8.ox, yBottom, 0, w, 1, 0, 0)

  local s9 = menuPanelGraphics.slices[9]
  s9.graphic:draw(xRight, yBottom, 0, 1, 1, 0, 0)
end

Component.create({
  id = 'slice-9',
  init = function(self)
    Component.addToGroup(self, 'gui')
  end,
  draw = function()
    love.graphics.push()
    love.graphics.origin()
    love.graphics.scale(4)

    love.graphics.setColor(0.5,0.5,0.5,0.5)
    love.graphics.rectangle('fill', 0, 0, 250, 200)

    love.graphics.setColor(1,1,0)
    love.graphics.rectangle('fill', 100, 60, 100, 100)

    local ok, err = pcall(function()
      slice9({
        x = 100,
        y = 60,
        w = 100,
        h = 100
      })
    end)

    if (not ok) then
      print(err)
    end

    love.graphics.pop()
  end
})