-- tests/test_focus_stack.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "BGUI/FocusStack"

local s = BGUI.FocusStack.new()
assert(s:depth() == 0)
assert(s:peek() == nil)
assert(s:pop() == nil)

s:push("dualpane")
s:push("radial")
assert(s:depth() == 2)
assert(s:peek() == "radial")
assert(s:pop() == "radial")
assert(s:peek() == "dualpane")
s:clear()
assert(s:depth() == 0)
assert(s:peek() == nil)
