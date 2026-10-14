-- media/lua/client/TLOZ/KbmShell.lua
TLOZ = TLOZ or {}
TLOZ.KbmShell = {}

function TLOZ.KbmShell:activate()
  -- vanilla ISUI permanece; apenas marca modo
  TLOZ._activeShell = "kbm"
end

function TLOZ.KbmShell:deactivate()
  -- nada a destruir no v1
end
