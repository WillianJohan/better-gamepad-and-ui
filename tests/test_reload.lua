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
  OnKeyStartPressed = makeEvent(),
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
BGUI.closeOpenUi()
BGUI.disarmEvents()
BGUI.clearLoadedModules()

package.loaded["BGUI/StubModule"] = { marker = true }
package.loaded["BGUI.OtherStub"] = { marker = true }
package.loaded["OtherMod/X"] = { keep = true }
BGUI.clearLoadedModules()
assert(package.loaded["BGUI/StubModule"] == nil, "clears BGUI/ keys")
assert(package.loaded["BGUI.OtherStub"] == nil, "clears BGUI. keys")
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
assert(type(BGUI.reload) == "function", "reload after bootstrap")
assert(BGUI._handlers and BGUI._handlers.tickHub, "handlers stored")

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
assert(type(BGUI.reload) == "function", "reload survives re-bootstrap")
assert(#removed > 0, "old events removed")
