-- tests/test_dualsense_policy.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "BGUI/DualSensePolicy"

assert(BGUI.DualSensePolicy.shouldUseAdaptive("ps") == true)
assert(BGUI.DualSensePolicy.shouldUseAdaptive("xbox") == false)
assert(BGUI.DualSensePolicy.shouldUseAdaptive(nil) == false)

local effect = BGUI.DualSensePolicy.holdEffect("hub")
assert(effect.resistance > 0)
local none = BGUI.DualSensePolicy.holdEffect("unknown")
assert(none.resistance == 0)

-- holdEffect item_radial também aplica
local itemFx = BGUI.DualSensePolicy.holdEffect("item_radial")
assert(itemFx.resistance > 0)
assert(itemFx.haptic > 0)

-- Hooks: no-op seguro sem backend / família xbox
package.path = package.path .. ";../media/lua/client/?.lua"
require "BGUI/DualSenseHooks"

BGUI._glyphFamily = "xbox"
BGUI._dualSenseBackend = nil
BGUI.DualSenseHooks.onHoldStart("hub")
BGUI.DualSenseHooks.onHoldEnd("hub")

BGUI._glyphFamily = "ps"
local applied, cleared = false, false
BGUI._dualSenseBackend = {
  apply = function(fx)
    applied = true
    assert(fx.resistance > 0)
  end,
  clear = function()
    cleared = true
  end,
}
BGUI.DualSenseHooks.onHoldStart("hub")
assert(applied, "ps + backend aplica efeito")
BGUI.DualSenseHooks.onHoldEnd("hub")
assert(cleared, "onHoldEnd limpa backend")

-- sem backend: não lança
BGUI._dualSenseBackend = nil
BGUI.DualSenseHooks.onHoldStart("item_radial")
BGUI.DualSenseHooks.onHoldEnd("item_radial")
