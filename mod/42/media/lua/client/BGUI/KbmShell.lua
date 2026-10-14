-- media/lua/client/BGUI/KbmShell.lua
BGUI = BGUI or {}
BGUI.KbmShell = {}

function BGUI.KbmShell:activate()
  -- vanilla ISUI permanece; apenas marca modo
  BGUI._activeShell = "kbm"
end

function BGUI.KbmShell:deactivate()
  -- nada a destruir no v1
end
