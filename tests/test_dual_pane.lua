-- tests/test_dual_pane.lua — lista + navegação dual-pane (stubs ISUI)
package.path = package.path
  .. ";../media/lua/shared/?.lua"
  .. ";../media/lua/client/?.lua"

ISPanel = {}
function ISPanel:new(x, y, w, h)
  return {
    x = x,
    y = y,
    width = w,
    height = h,
    children = {},
    drawRect = function() end,
    drawText = function() end,
    addChild = function(self, c) self.children[#self.children + 1] = c end,
    setVisible = function() end,
    addToUIManager = function() end,
    removeFromUIManager = function() end,
  }
end
function ISPanel:derive(_)
  local Derived = {}
  Derived.__index = Derived
  function Derived:new(...)
    local o = ISPanel:new(...)
    setmetatable(o, Derived)
    return o
  end
  return Derived
end

UIFont = { Medium = "Medium", Small = "Small" }

function getCore()
  return {
    getScreenWidth = function() return 800 end,
    getScreenHeight = function() return 600 end,
  }
end

function getSpecificPlayer()
  return nil
end

TLOZ = TLOZ or {}
TLOZ._focus = TLOZ.FocusStack and TLOZ.FocusStack.new() or { push = function() end, pop = function() end, peek = function() return "dualpane" end }
TLOZ.GamepadShell = { hideVanillaInventory = function() end }

require "TLOZ/FocusStack"
require "TLOZ/CategoryFilter"
require "TLOZ/InventoryListPane"
require "TLOZ/DualPaneInventory"

local pane = TLOZ.InventoryListPane:new(0, 0, 200, 300, "VOCÊ")
pane:setRows({ { label = "a" }, { label = "b" }, { label = "c" } })
pane:moveSelection(1)
assert(pane.selected == 2, "move down")
pane:moveSelection(1)
pane:moveSelection(1)
assert(pane.selected == 1, "wrap selection")
pane:setRows({ { label = "only" } })
assert(pane.selected == 1, "clamp selection after shrink")

local dp = TLOZ.DualPaneInventory:new(0)
assert(dp.side == "you" and dp.youTab == "equipped", "initial state")
dp:onSwapSide()
assert(dp.side == "reach", "swap to reach")
dp:onTabOrCycle(1)
assert(dp.youTab == "equipped", "tab unchanged when focus reach")
dp:onSwapSide()
dp:onTabOrCycle(1)
assert(dp.youTab == "backpack", "L1/R1 toggles equipped/backpack on you side")
dp:onCycleCategory(1)
assert(dp.categoryId ~= "weapons" or TLOZ.CategoryFilter.cycle("weapons", 1) == dp.categoryId, "category cycles on backpack")
dp.youTab = "equipped"
local before = dp.categoryId
dp:onCycleCategory(1)
assert(dp.categoryId == before, "no category cycle on equipped tab")
