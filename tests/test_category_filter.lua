-- tests/test_category_filter.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "BGUI/Strings_PT"
require "BGUI/CategoryFilter"

local C = BGUI.CategoryFilter
assert(#C.ORDER >= 8)
assert(C.classify("Base.Axe") == "weapons")
assert(C.classify("Base.Bullets9mm") == "ammo")
assert(C.classify("Base.Tshirt_White") == "clothes")
assert(C.classify("Base.Apple") == "food")
assert(C.classify("Base.WaterBottleFull") == "water")
assert(C.classify("Base.Bandage") == "medical")
assert(C.classify("Base.Bag") == "containers")
assert(C.classify("Base.Hammer") == "tools")
assert(C.classify("Base.Newspaper") == "misc")

local items = {
  { type = "Base.Axe" },
  { type = "Base.Apple" },
  { type = "Base.Hammer" },
}
local weapons = C.filter(items, "weapons")
assert(#weapons == 1 and weapons[1].type == "Base.Axe")

local id = "weapons"
id = C.cycle(id, 1)
assert(id == "ammo")
id = C.cycle("misc", 1)
assert(id == "weapons", "wrap forward")
id = C.cycle("weapons", -1)
assert(id == "misc", "wrap back")
