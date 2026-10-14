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
TLOZ = TLOZ or {}
TLOZ.ButtonLegend = {
  new = function(_, x, y, w, h)
    return {
      _x = x, _y = y, _w = w, _h = h,
      setContext = function() end,
      addToUIManager = function() legendVisible = true end,
      removeFromUIManager = function() legendVisible = false end,
    }
  end,
}

require "TLOZ/InputMode"
require "TLOZ/InputRouter"
require "TLOZ/FocusStack"
require "TLOZ/KbmShell"
require "TLOZ/GamepadShell"
require "TLOZ/UIShell"

local router = TLOZ.InputRouter.new()
TLOZ.UIShell.start(router)

assert(TLOZ._activeShell == "kbm", "starts kbm")
assert(router:getMode() == TLOZ.InputMode.KBM)
assert(not legendVisible, "no legend in kbm")

router:onDecisiveInput("gamepad")
assert(TLOZ._activeShell == "gamepad", "enters gamepad shell")
assert(router:getMode() == TLOZ.InputMode.GAMEPAD)
assert(legendVisible, "legend shown in gamepad")
assert(TLOZ._focus and TLOZ._focus:peek() == "world", "focus world")

router:onDecisiveInput("keyboard")
assert(TLOZ._activeShell == "kbm", "returns to kbm shell")
assert(router:getMode() == TLOZ.InputMode.KBM)
assert(not legendVisible, "legend removed on exit")
assert(TLOZ._legend == nil, "legend ref cleared")

router:onDecisiveInput("gamepad")
assert(legendVisible, "legend recreated on re-enter")

-- Atalho veículo no tick world (perto/dentro)
require "TLOZ/InputMode"
TLOZ._router = router
router:forceMode(TLOZ.InputMode.GAMEPAD)
TLOZ._activeShell = "gamepad"
TLOZ._focus = TLOZ.FocusStack.new()
TLOZ._focus:push("world")
function getSpecificPlayer(_)
  return {}
end
local vehicleOpened = false
TLOZ.RadialSatellites = {
  canUseVehicleShortcut = function() return true end,
  openVehicle = function() vehicleOpened = true end,
  openWorld = function() error("world should not open near vehicle") end,
}
TLOZ._testConfirmHeld = true
TLOZ._worldRadialHoldMs = 0
TLOZ._worldRadialOpened = false
UIManager = { getMillisDelta = function() return 300 end }
TLOZ.GamepadShell:tickSatellites(0)
assert(vehicleOpened, "near vehicle hold A opens openVehicle")
TLOZ._testConfirmHeld = nil
