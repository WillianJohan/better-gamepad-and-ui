-- tests/test_input_router.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "BGUI/InputMode"
require "BGUI/InputRouter"

local r = BGUI.InputRouter.new()
assert(r:getMode() == BGUI.InputMode.KBM, "default kbm")

local entered, exited = 0, 0
r:onEnterGamepad(function() entered = entered + 1 end)
r:onExitGamepad(function() exited = exited + 1 end)

r:onDecisiveInput("gamepad")
assert(r:getMode() == BGUI.InputMode.GAMEPAD, "enter gamepad")
assert(entered == 1, "enter once")

r:onDecisiveInput("gamepad")
assert(entered == 1, "idempotent while already gamepad")

r:onDecisiveInput("keyboard")
assert(r:getMode() == BGUI.InputMode.KBM, "exit to kbm")
assert(exited == 1, "exit once")

r:onDecisiveInput("mouse")
assert(r:getMode() == BGUI.InputMode.KBM)
assert(exited == 1, "still kbm, no double exit")

r:forceMode(BGUI.InputMode.GAMEPAD)
assert(r:getMode() == BGUI.InputMode.GAMEPAD)
assert(entered == 2, "forceMode fires enter")
