-- media/lua/client/BGUI/UIShell.lua
require "BGUI/InputRouter"
require "BGUI/KbmShell"
require "BGUI/GamepadShell"

BGUI = BGUI or {}
BGUI.UIShell = {}

function BGUI.UIShell.start(router)
  BGUI._router = router
  BGUI._activeShell = BGUI._activeShell or "kbm"
  BGUI.KbmShell:activate()
  router:onEnterGamepad(function()
    BGUI.KbmShell:deactivate()
    BGUI.GamepadShell:activate()
  end)
  router:onExitGamepad(function()
    BGUI.GamepadShell:deactivate()
    BGUI.KbmShell:activate()
  end)
end
