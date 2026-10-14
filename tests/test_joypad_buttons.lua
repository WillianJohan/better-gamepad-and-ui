-- tests/test_joypad_buttons.lua — poll B42 (controller.pressed / JoypadButton)
package.path = package.path
  .. ";../mod/42/media/lua/shared/?.lua"
  .. ";../mod/42/media/lua/shared/?/?.lua"
  .. ";../mod/42/media/lua/client/?.lua"
  .. ";../mod/42/media/lua/client/?/?.lua"

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
UIManager = { getMillisDelta = function() return 16 end }
function getSpecificPlayer() return nil end
function getNumActivePlayers() return 1 end

-- Stub B42: Joypad.YButton é enum; pressed[] indexado por fromIndex
JoypadButton = {
  A = { name = "A" },
  B = { name = "B" },
  X = { name = "X" },
  Y = { name = "Y" },
  LeftBump = { name = "LB" },
  RightBump = { name = "RB" },
}
local INDEX = {
  [JoypadButton.A] = 0,
  [JoypadButton.B] = 1,
  [JoypadButton.X] = 2,
  [JoypadButton.Y] = 3,
  [JoypadButton.LeftBump] = 4,
  [JoypadButton.RightBump] = 5,
}
function JoypadButton.fromIndex(n)
  for b, i in pairs(INDEX) do
    if i == n then return b end
  end
  return nil
end
function JoypadButton.toIndex(b)
  return INDEX[b]
end
function JoypadButton.isButtonDown(id, n)
  local c = JoypadState.controllers[id]
  return c and c.pressed and c.pressed[n] == true
end

Joypad = {
  AButton = JoypadButton.A,
  BButton = JoypadButton.B,
  XButton = JoypadButton.X,
  YButton = JoypadButton.Y,
  LBumper = JoypadButton.LeftBump,
  RBumper = JoypadButton.RightBump,
}

JoypadState = {
  players = {},
  controllers = {
    [0] = { id = 0, pressed = { [0] = false, [3] = false, [4] = false }, connected = true },
  },
  joypads = {},
}

BGUI = {}
package.loaded["BGUI/FocusStack"] = nil
package.loaded["BGUI/RadialHub"] = nil
package.loaded["BGUI/DualSenseHooks"] = nil
package.loaded["BGUI/GamepadShell"] = nil
require "BGUI/FocusStack"
require "BGUI/GamepadShell"

assert(type(BGUI.joypadButtonIndex) == "function", "joypadButtonIndex exposed")
assert(BGUI.joypadButtonIndex("YButton", 3) == 3, "Y index from Joypad.YButton")
assert(BGUI.joypadButtonIndex("LBumper", 4) == 4, "LB index")

JoypadState.players[1] = {
  id = 0,
  controller = JoypadState.controllers[0],
}

assert(BGUI.GamepadShell:_yHeld(0) == false, "Y up")
JoypadState.controllers[0].pressed[3] = true
assert(BGUI.GamepadShell:_yHeld(0) == true, "Y via controller.pressed")
JoypadState.controllers[0].pressed[3] = false
assert(BGUI.GamepadShell:_yHeld(0) == false, "Y released")

-- fallback JoypadButton.isButtonDown quando pressed ausente
JoypadState.players[1].controller = { id = 0 }
JoypadState.controllers[0].pressed[3] = true
assert(BGUI.GamepadShell:_yHeld(0) == true, "Y via isButtonDown fallback")

print("OK test_joypad_buttons")
