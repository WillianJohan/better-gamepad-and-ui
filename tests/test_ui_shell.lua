-- tests/test_ui_shell.lua — swap total via InputRouter (stubs ISUI)
package.path = package.path
  .. ";../media/lua/shared/?.lua"
  .. ";../media/lua/client/?.lua"

function getCore()
  return {
    getScreenHeight = function() return 600 end,
    getScreenWidth = function() return 800 end,
  }
end

ISPanel = {}
function ISPanel:new(x, y, w, h)
  return { x = x, y = y, width = w, height = h }
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
UIFont = { Small = "Small" }

local legendVisible = false
BGUI = BGUI or {}
BGUI.ButtonLegend = {
  new = function(_, x, y, w, h)
    return {
      _x = x, _y = y, _w = w, _h = h,
      setContext = function() end,
      addToUIManager = function() legendVisible = true end,
      removeFromUIManager = function() legendVisible = false end,
    }
  end,
}

require "BGUI/InputMode"
require "BGUI/InputRouter"
require "BGUI/FocusStack"
require "BGUI/KbmShell"
require "BGUI/GamepadShell"
require "BGUI/UIShell"

local router = BGUI.InputRouter.new()
BGUI.UIShell.start(router)

assert(BGUI._activeShell == "kbm", "starts kbm")
assert(router:getMode() == BGUI.InputMode.KBM)
assert(not legendVisible, "no legend in kbm")

router:onDecisiveInput("gamepad")
assert(BGUI._activeShell == "gamepad", "enters gamepad shell")
assert(router:getMode() == BGUI.InputMode.GAMEPAD)
assert(legendVisible, "legend shown in gamepad")
assert(BGUI._focus and BGUI._focus:peek() == "world", "focus world")

router:onDecisiveInput("keyboard")
assert(BGUI._activeShell == "kbm", "returns to kbm shell")
assert(router:getMode() == BGUI.InputMode.KBM)
assert(not legendVisible, "legend removed on exit")
assert(BGUI._legend == nil, "legend ref cleared")

router:onDecisiveInput("gamepad")
assert(legendVisible, "legend recreated on re-enter")

-- Atalho veículo no tick world (perto/dentro)
require "BGUI/InputMode"
BGUI._router = router
router:forceMode(BGUI.InputMode.GAMEPAD)
BGUI._activeShell = "gamepad"
BGUI._focus = BGUI.FocusStack.new()
BGUI._focus:push("world")
function getSpecificPlayer(_)
  return {}
end
local vehicleOpened = false
BGUI.RadialSatellites = {
  canUseVehicleShortcut = function() return true end,
  openVehicle = function() vehicleOpened = true end,
  openWorld = function() error("world should not open near vehicle") end,
}
BGUI._testConfirmHeld = true
BGUI._worldRadialHoldMs = 0
BGUI._worldRadialOpened = false
UIManager = { getMillisDelta = function() return 300 end }
BGUI.GamepadShell:tickSatellites(0)
assert(vehicleOpened, "near vehicle hold A opens openVehicle")
BGUI._testConfirmHeld = nil
