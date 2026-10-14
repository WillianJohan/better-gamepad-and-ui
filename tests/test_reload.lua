-- tests/test_reload.lua — smoke do hot-reload (fora do jogo)
package.path = package.path
  .. ";../mod/42/media/lua/shared/?.lua"
  .. ";../mod/42/media/lua/shared/?/?.lua"
  .. ";../mod/42/media/lua/client/?.lua"
  .. ";../mod/42/media/lua/client/?/?.lua"

local removed = {}
local added = {}
local function makeEvent()
  -- PZ: Events.OnTick.Add(fn) — sem self
  return {
    Add = function(fn)
      added[#added + 1] = fn
    end,
    Remove = function(fn)
      removed[#removed + 1] = fn
    end,
  }
end

Events = {
  OnTick = makeEvent(),
  OnJoypadActivate = makeEvent(),
  OnJoypadActivateUI = makeEvent(),
  OnJoypadReactivate = makeEvent(),
  OnGamepadConnect = makeEvent(),
  OnGameStart = makeEvent(),
  OnCreatePlayer = makeEvent(),
  OnKeyStartPressed = makeEvent(),
  OnKeyPressed = makeEvent(),
  OnJoypadButtonPressed = makeEvent(),
}

function getCore()
  return {
    getScreenHeight = function() return 600 end,
    getScreenWidth = function() return 800 end,
  }
end

local function makeUiBase()
  local Base = {}
  function Base:new(x, y, w, h)
    return {
      x = x,
      y = y,
      width = w,
      height = h,
      children = {},
      drawRect = function() end,
      drawText = function() end,
      addChild = function(self, c) self.children[#self.children + 1] = c end,
      setVisible = function() end,
      addToUIManager = function() end,
      removeFromUIManager = function() end,
    }
  end
  function Base:derive(_)
    local Derived = {}
    Derived.__index = Derived
    function Derived:new(...)
      local o = Base:new(...)
      setmetatable(o, Derived)
      return o
    end
    return Derived
  end
  return Base
end

ISPanel = makeUiBase()
ISUIElement = makeUiBase()
UIFont = { Small = "Small", Medium = "Medium" }
UIManager = { getMillisDelta = function() return 16 end }

function getSpecificPlayer()
  return nil
end

-- closeOpenUi / disarm / clear quando já limpo
BGUI = {}
require "BGUI/Debug"
assert(type(BGUI.reload) == "function", "BGUI.reload exposed")
assert(type(BGUI.status) == "function", "BGUI.status exposed")
assert(type(BGUI_rebootstrap) == "function", "BGUI_rebootstrap global")
BGUI.closeOpenUi()
BGUI.disarmEvents()
BGUI.clearLoadedModules()

package.loaded["BGUI/StubModule"] = { marker = true }
package.loaded["BGUI.OtherStub"] = { marker = true }
package.loaded["BGUI\\bootstrap"] = { marker = true }
package.loaded["media/lua/client/BGUI/Debug"] = { marker = true }
package.loaded["OtherMod/X"] = { keep = true }
BGUI.clearLoadedModules()
assert(package.loaded["BGUI/StubModule"] == nil, "clears BGUI/ keys")
assert(package.loaded["BGUI.OtherStub"] == nil, "clears BGUI. keys")
assert(package.loaded["BGUI\\bootstrap"] == nil, "clears BGUI\\\\ path keys")
assert(package.loaded["media/lua/client/BGUI/Debug"] == nil, "clears path-prefixed BGUI keys")
assert(package.loaded["OtherMod/X"] ~= nil, "leaves non-BGUI keys")

-- painel aberto fecha sem crash
local closed = false
BGUI._dualPane = {
  close = function() closed = true end,
}
BGUI.closeOpenUi()
assert(closed, "dual pane closed")
assert(BGUI._dualPane == nil, "dual pane ref cleared")

-- bootstrap + reload completo (stubs de Events / ISUI)
package.loaded["BGUI/Debug"] = nil
package.loaded["BGUI/bootstrap"] = nil
BGUI = {}
require "BGUI/bootstrap"
assert(BGUI._router ~= nil, "router armed")
assert(BGUI._bootOk == true, "bootOk set")
assert(BGUI._activeShell ~= nil, "activeShell set after start")
assert(type(BGUI.reload) == "function", "reload after bootstrap")
assert(type(BGUI.status) == "function", "status after bootstrap")
assert(BGUI._handlers and BGUI._handlers.tickHub, "handlers stored")

local st = BGUI.status()
assert(st.bootOk == true, "status reports bootOk")
assert(st.mode == "kbm" or st.mode == "gamepad", "status reports mode")

local paneClosed = false
BGUI._dualPane = {
  close = function() paneClosed = true end,
}
BGUI._radialHub = {
  close = function() end,
}
package.loaded["BGUI/StubAfterBoot"] = {}

local ok = BGUI.reload()
assert(ok == true, "reload returns true")
assert(paneClosed, "reload closes open UI")
assert(package.loaded["BGUI/StubAfterBoot"] == nil, "reload cleared stub package.loaded")
assert(BGUI._router ~= nil, "router re-armed")
assert(BGUI._bootOk == true, "bootOk after reload")
assert(BGUI._activeShell ~= nil, "activeShell after reload")
assert(type(BGUI.reload) == "function", "reload survives re-bootstrap")
assert(type(BGUI.status) == "function", "status survives re-bootstrap")
assert(#removed > 0, "old events removed")

-- Tabela half-dead (reload nil) → BGUI_rebootstrap recupera
BGUI.reload = nil
BGUI.status = nil
BGUI._router = nil
BGUI._bootOk = false
local rb = BGUI_rebootstrap()
assert(rb == true, "rebootstrap recovers")
assert(type(BGUI.reload) == "function", "reload restored")
assert(type(BGUI.status) == "function", "status restored")
assert(BGUI._router ~= nil, "router restored")
assert(BGUI._bootOk == true, "bootOk after rebootstrap")

-- Joypad já atribuído no bootstrap → força gamepad
JoypadState = {
  players = {
    [1] = { controller = { getName = function() return "Xbox Controller" end } },
  },
}
assert(BGUI_rebootstrap() == true, "rebootstrap with joypad")
assert(BGUI._router ~= nil, "router with joypad")
assert(BGUI._router:getMode() == BGUI.InputMode.GAMEPAD, "probe forces gamepad")
assert(BGUI._activeShell == "gamepad", "shell is gamepad when pad assigned")
JoypadState = nil

-- Globals resilientes no console (não morrem com wipe da tabela BGUI)
assert(type(BGUI_reload) == "function", "BGUI_reload global")
assert(type(BGUI_status) == "function", "BGUI_status global")
BGUI.reload = nil
BGUI.status = nil
local rbViaGlobal = BGUI_reload()
assert(rbViaGlobal == true, "BGUI_reload recovers when table helpers are nil")
assert(type(BGUI.reload) == "function", "BGUI_reload restored table.reload")
local st2 = BGUI_status()
assert(st2 and st2.bootOk == true, "BGUI_status works via global")

-- require no-op (simula cache Kahlua) não pode matar helpers nem mentir "ok"
local realRequire = _G.require
local swallowBootstrap = true
_G.require = function(name)
  if swallowBootstrap and (name == "BGUI/bootstrap" or name == "BGUI\\bootstrap") then
    return package.loaded[name] or true
  end
  return realRequire(name)
end
local keepRouter = BGUI._router
local okNoop = BGUI.reload()
swallowBootstrap = false
_G.require = realRequire
assert(okNoop == false, "no-op require must fail reload")
assert(type(BGUI.reload) == "function", "helpers survive no-op require")
assert(type(BGUI.status) == "function", "status survives no-op require")
assert(BGUI_rebootstrap() == true, "rebootstrap after no-op require")
assert(BGUI._router ~= nil, "router after rebootstrap")
assert(keepRouter ~= nil, "had router before no-op test")
