-- media/lua/shared/BGUI/ButtonLegendModel.lua
BGUI = BGUI or {}
BGUI.ButtonLegendModel = {}
require "BGUI/Strings_PT"
require "BGUI/JoypadBindMap"

function BGUI.ButtonLegendModel.buildEntries(context, family)
  local g = function(a) return BGUI.JoypadBindMap.glyph(family, a) end
  local S = BGUI.Strings
  if context == "dualpane_you" or context == "dualpane_reach" then
    return {
      { glyph = g("swapSide"), label = S.swapSide },
      { glyph = g("confirm"), label = S.transfer },
      { glyph = g("cancel"), label = S.back },
      { glyph = g("openInv"), label = S.close },
      { glyph = g("itemRadial"), label = S.radialWorld },
      { glyph = g("tabPrev") .. "/" .. g("tabNext"), label = S.tabEquipped .. "/" .. S.tabBackpack },
    }
  elseif context == "radial_open" then
    return {
      { glyph = g("confirm"), label = S.legendConfirm },
      { glyph = g("cancel"), label = S.legendCancel },
    }
  else
    return {
      { glyph = g("hub"), label = S.radialInventory },
      { glyph = g("openInv"), label = S.radialInventory },
    }
  end
end
