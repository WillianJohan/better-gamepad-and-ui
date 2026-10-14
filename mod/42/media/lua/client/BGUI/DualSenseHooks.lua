-- media/lua/client/BGUI/DualSenseHooks.lua
require "BGUI/DualSensePolicy"

BGUI = BGUI or {}
BGUI.DualSenseHooks = {}

local function nativeApply(effect)
  -- Integração: Steam Input / API nativa se exposta ao Lua na build.
  -- Se nenhuma API existir, permanece no-op (fallback elegante).
  if BGUI._dualSenseBackend and BGUI._dualSenseBackend.apply then
    BGUI._dualSenseBackend.apply(effect)
  end
end

local function nativeClear()
  if BGUI._dualSenseBackend and BGUI._dualSenseBackend.clear then
    BGUI._dualSenseBackend.clear()
  end
end

function BGUI.DualSenseHooks.onHoldStart(kind)
  if not BGUI.DualSensePolicy.shouldUseAdaptive(BGUI._glyphFamily) then
    return
  end
  nativeApply(BGUI.DualSensePolicy.holdEffect(kind))
end

function BGUI.DualSenseHooks.onHoldEnd(kind)
  nativeClear()
end
