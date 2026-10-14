-- media/lua/client/TLOZ/UIShell.lua
require "TLOZ/InputRouter"
require "TLOZ/KbmShell"
require "TLOZ/GamepadShell"

TLOZ = TLOZ or {}
TLOZ.UIShell = {}

function TLOZ.UIShell.start(router)
  TLOZ._router = router
  TLOZ.KbmShell:activate()
  router:onEnterGamepad(function()
    TLOZ.KbmShell:deactivate()
    TLOZ.GamepadShell:activate()
  end)
  router:onExitGamepad(function()
    TLOZ.GamepadShell:deactivate()
    TLOZ.KbmShell:activate()
  end)
end
