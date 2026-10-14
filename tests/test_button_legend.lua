-- tests/test_button_legend.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "BGUI/Strings_PT"
require "BGUI/JoypadBindMap"
require "BGUI/ButtonLegendModel"

assert(BGUI.JoypadBindMap.detectFamily("DualSense Wireless Controller") == "ps")
assert(BGUI.JoypadBindMap.detectFamily("Xbox One Controller") == "xbox")

local e = BGUI.ButtonLegendModel.buildEntries("dualpane_you", "ps")
assert(#e >= 4)
assert(e[1].glyph == "□")
assert(e[1].label == "Trocar lado")

local r = BGUI.ButtonLegendModel.buildEntries("radial_open", "xbox")
assert(r[1].glyph == "A")
assert(r[1].label == "Confirmar")
