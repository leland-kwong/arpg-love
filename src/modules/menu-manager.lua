--[[
  Menu manager

  Allows menus to stack on top of each other.
  Menus are deleted during `pop` and `clear` operations.
]]

local StackManager = require 'utils.stack-manager'

local stack = StackManager.new()
local MenuManager = {
  stack = stack
}

local activeMenu = nil

function MenuManager.push(menu)
  stack:push(menu)
  activeMenu = menu
  return MenuManager
end

function MenuManager.pop()
  if activeMenu then
    activeMenu:delete(true)
  end

  local previousMenu = stack:pop()
  activeMenu = previousMenu
  return MenuManager
end

function MenuManager.clearAll()
  local allMenus = stack:popAll()
  activeMenu = nil
  for i=1, #allMenus do
    local menu = allMenus[i]
    menu:delete(true)
  end
  return MenuManager
end

function MenuManager.popToFirst()
  while #stack.stack > 1 do
    stack:pop()
  end
  return MenuManager
end

function MenuManager.hasItems()
  return #MenuManager.stack.stack > 0
end

return MenuManager