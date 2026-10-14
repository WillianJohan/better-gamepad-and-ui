-- media/lua/shared/TLOZ/DualSensePolicy.lua
TLOZ = TLOZ or {}
TLOZ.DualSensePolicy = {}

function TLOZ.DualSensePolicy.shouldUseAdaptive(family)
  return family == "ps"
end

function TLOZ.DualSensePolicy.holdEffect(kind)
  if kind == "hub" or kind == "item_radial" then
    return { resistance = 0.45, haptic = 0.2 }
  end
  return { resistance = 0, haptic = 0 }
end
