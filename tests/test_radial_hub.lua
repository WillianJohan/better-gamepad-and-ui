-- tests/test_radial_hub.lua — hub radial (≤8 fatias, inventário → DualPane, despacho vanilla)
package.path = package.path
  .. ";../media/lua/shared/?.lua"
  .. ";../media/lua/client/?.lua"

ISPanel = {}
function ISPanel:new(x, y, w, h)
  return {
    x = x,
    y = y,
    width = w,
    height = h,
    drawRect = function() end,
    drawTextCentre = function() end,
    addToUIManager = function() end,
    removeFromUIManager = function() end,
  }
end
function ISPanel:derive(_)
  local Derived = {}
  Derived.__index = Derived
  function Derived:new(...)
    local o = ISPanel:new(...)
    setmetatable(o, Derived)
    return o
  end
  return Derived
end

UIFont = { Small = "Small" }

function getCore()
  return {
    getScreenWidth = function() return 800 end,
    getScreenHeight = function() return 600 end,
  }
end

local playerStub = {
  getPlayerNum = function() return 0 end,
}
function getSpecificPlayer()
  return playerStub
end

xpSystemText = { health = "Health", skills = "Skills", character = "Character" }

local calls = {}
getPlayerInfoPanel = function(n)
  assert(n == 0, "playerNum 0")
  return {
    toggleView = function(_, name)
      calls[#calls + 1] = { "info", name }
    end,
  }
end

ISWorldMap = {
  ToggleWorldMap = function(n)
    calls[#calls + 1] = { "map", n }
  end,
}

ISCraftingUI = {
  toggleCraftingUI = function()
    calls[#calls + 1] = { "craft" }
  end,
}

MainScreen = {
  instance = {
    setVisible = function(_, v)
      calls[#calls + 1] = { "options", v }
    end,
    getIsVisible = function() return false end,
  },
}

require "TLOZ/FocusStack"
require "TLOZ/RadialSlice"
require "TLOZ/Strings_PT"
package.loaded["TLOZ/RadialHub"] = nil
require "TLOZ/RadialHub"
package.loaded["TLOZ/RadialSatellites"] = nil
-- stub satellites so hub build slice can call openBuild without full sat file deps
TLOZ.RadialSatellites = {
  openBuild = function()
    calls[#calls + 1] = { "build" }
  end,
}

TLOZ._focus = TLOZ.FocusStack.new()
TLOZ._focus:push("world")
TLOZ._legend = { setContext = function(_, ctx)
  TLOZ._lastLegendCtx = ctx
end }

local hub = TLOZ.RadialHub:new()
hub:open()
assert(TLOZ._focus:peek() == "radial_hub", "focus radial_hub")
assert(TLOZ._lastLegendCtx == "radial_open", "legend radial_open")
assert(#hub.slices == 7, "seven hub slices")
assert(#hub.slices <= 8, "max eight slices")

local expected = {
  inventory = "Inventário",
  health = "Saúde",
  map = "Mapa",
  craft = "Criar",
  build = "Construir",
  character = "Personagem",
  options = "Opções",
}
for i, s in ipairs(hub.slices) do
  assert(expected[s.id] == s.label, "PT label for " .. s.id)
  assert(not string.find(s.label, "getFullType", 1, true), "hub is not loot browser")
end

hub:setStickDirection(-math.pi / 2)
assert(hub.selected == 1, "stick up selects first slice")

local dualOpened = false
TLOZ.openDualPane = function(n)
  dualOpened = true
  assert(n == 0, "player 0")
end
hub.selected = 1
hub:confirm()
assert(dualOpened, "inventory slice opens DualPane")
assert(TLOZ._focus:peek() == "world", "hub closed restores world focus")

local function confirmSlice(id)
  hub:open()
  for i, s in ipairs(hub.slices) do
    if s.id == id then hub.selected = i end
  end
  local before = #calls
  hub:confirm()
  return before
end

local before = confirmSlice("health")
assert(calls[#calls] and calls[#calls][1] == "info", "health opens character info")
assert(calls[#calls][2] == "Health", "health toggles Health view")

before = confirmSlice("map")
assert(calls[#calls] and calls[#calls][1] == "map", "map ToggleWorldMap")
assert(calls[#calls][2] == 0, "map playerNum")

before = confirmSlice("craft")
assert(calls[#calls] and calls[#calls][1] == "craft", "craft toggleCraftingUI")

before = confirmSlice("character")
assert(calls[#calls] and calls[#calls][1] == "info", "character opens info")
assert(calls[#calls][2] == "Skills" or calls[#calls][2] == "Character", "skills/character view")

before = confirmSlice("options")
assert(calls[#calls] and calls[#calls][1] == "options", "options opens MainScreen")

before = confirmSlice("build")
assert(calls[#calls] and calls[#calls][1] == "build", "build opens satellite")

hub:open()
hub:close()
assert(TLOZ._focus:peek() == "world", "close pops focus")
