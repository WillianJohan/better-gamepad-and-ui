-- media/lua/shared/BGUI/DualSensePolicy.lua
BGUI = BGUI or {}
BGUI.DualSensePolicy = {}

function BGUI.DualSensePolicy.shouldUseAdaptive(family)
  return family == "ps"
end

function BGUI.DualSensePolicy.holdEffect(kind)
  if kind == "hub" or kind == "item_radial" then
    return { resistance = 0.45, haptic = 0.2 }
  end
  return { resistance = 0, haptic = 0 }
end
