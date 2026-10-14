-- tests/test_dualsense_policy.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/DualSensePolicy"

assert(TLOZ.DualSensePolicy.shouldUseAdaptive("ps") == true)
assert(TLOZ.DualSensePolicy.shouldUseAdaptive("xbox") == false)
assert(TLOZ.DualSensePolicy.shouldUseAdaptive(nil) == false)

local effect = TLOZ.DualSensePolicy.holdEffect("hub")
assert(effect.resistance > 0)
local none = TLOZ.DualSensePolicy.holdEffect("unknown")
assert(none.resistance == 0)

-- holdEffect item_radial também aplica
local itemFx = TLOZ.DualSensePolicy.holdEffect("item_radial")
assert(itemFx.resistance > 0)
assert(itemFx.haptic > 0)

-- Hooks: no-op seguro sem backend / família xbox
package.path = package.path .. ";../media/lua/client/?.lua"
require "TLOZ/DualSenseHooks"

TLOZ._glyphFamily = "xbox"
TLOZ._dualSenseBackend = nil
TLOZ.DualSenseHooks.onHoldStart("hub")
TLOZ.DualSenseHooks.onHoldEnd("hub")

TLOZ._glyphFamily = "ps"
local applied, cleared = false, false
TLOZ._dualSenseBackend = {
  apply = function(fx)
    applied = true
    assert(fx.resistance > 0)
  end,
  clear = function()
    cleared = true
  end,
}
TLOZ.DualSenseHooks.onHoldStart("hub")
assert(applied, "ps + backend aplica efeito")
TLOZ.DualSenseHooks.onHoldEnd("hub")
assert(cleared, "onHoldEnd limpa backend")

-- sem backend: não lança
TLOZ._dualSenseBackend = nil
TLOZ.DualSenseHooks.onHoldStart("item_radial")
TLOZ.DualSenseHooks.onHoldEnd("item_radial")
