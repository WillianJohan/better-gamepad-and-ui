-- tests/test_input_router.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/InputMode"
require "TLOZ/InputRouter"

local r = TLOZ.InputRouter.new()
assert(r:getMode() == TLOZ.InputMode.KBM, "default kbm")

local entered, exited = 0, 0
r:onEnterGamepad(function() entered = entered + 1 end)
r:onExitGamepad(function() exited = exited + 1 end)

r:onDecisiveInput("gamepad")
assert(r:getMode() == TLOZ.InputMode.GAMEPAD, "enter gamepad")
assert(entered == 1, "enter once")

r:onDecisiveInput("gamepad")
assert(entered == 1, "idempotent while already gamepad")

r:onDecisiveInput("keyboard")
assert(r:getMode() == TLOZ.InputMode.KBM, "exit to kbm")
assert(exited == 1, "exit once")

r:onDecisiveInput("mouse")
assert(r:getMode() == TLOZ.InputMode.KBM)
assert(exited == 1, "still kbm, no double exit")

r:forceMode(TLOZ.InputMode.GAMEPAD)
assert(r:getMode() == TLOZ.InputMode.GAMEPAD)
assert(entered == 2, "forceMode fires enter")
