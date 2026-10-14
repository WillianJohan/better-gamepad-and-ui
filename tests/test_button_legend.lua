-- tests/test_button_legend.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/Strings_PT"
require "TLOZ/JoypadBindMap"
require "TLOZ/ButtonLegendModel"

assert(TLOZ.JoypadBindMap.detectFamily("DualSense Wireless Controller") == "ps")
assert(TLOZ.JoypadBindMap.detectFamily("Xbox One Controller") == "xbox")

local e = TLOZ.ButtonLegendModel.buildEntries("dualpane_you", "ps")
assert(#e >= 4)
assert(e[1].glyph == "□")
assert(e[1].label == "Trocar lado")

local r = TLOZ.ButtonLegendModel.buildEntries("radial_open", "xbox")
assert(r[1].glyph == "A")
assert(r[1].label == "Confirmar")
