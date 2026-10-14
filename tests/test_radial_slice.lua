-- tests/test_radial_slice.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/RadialSlice"

local candidates = {}
for i = 1, 10 do
  candidates[i] = { id = "s" .. i, label = "S" .. i, enabled = i ~= 3 }
end
local slices = TLOZ.RadialSlice.build(candidates)
assert(#slices <= 8)
assert(#slices == 8, "drop empty + cap at 8 from 9 enabled")
for _, s in ipairs(slices) do
  assert(s.id ~= "s3", "disabled excluded")
end

local none = TLOZ.RadialSlice.build({
  { id = "a", label = "A", enabled = false },
})
assert(#none == 0)
