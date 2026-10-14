-- media/lua/client/TLOZ/DualSenseHooks.lua
require "TLOZ/DualSensePolicy"

TLOZ = TLOZ or {}
TLOZ.DualSenseHooks = {}

local function nativeApply(effect)
  -- Integração: Steam Input / API nativa se exposta ao Lua na build.
  -- Se nenhuma API existir, permanece no-op (fallback elegante).
  if TLOZ._dualSenseBackend and TLOZ._dualSenseBackend.apply then
    TLOZ._dualSenseBackend.apply(effect)
  end
end

local function nativeClear()
  if TLOZ._dualSenseBackend and TLOZ._dualSenseBackend.clear then
    TLOZ._dualSenseBackend.clear()
  end
end

function TLOZ.DualSenseHooks.onHoldStart(kind)
  if not TLOZ.DualSensePolicy.shouldUseAdaptive(TLOZ._glyphFamily) then
    return
  end
  nativeApply(TLOZ.DualSensePolicy.holdEffect(kind))
end

function TLOZ.DualSenseHooks.onHoldEnd(kind)
  nativeClear()
end
