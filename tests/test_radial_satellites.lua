-- tests/test_radial_satellites.lua — whitelist radial satélites (item/mundo/equip)
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
  getCurrentSquare = function() return nil end,
  getInventory = function() return { Remove = function() end } end,
  getVehicle = function() return nil end,
}
function getSpecificPlayer()
  return playerStub
end

require "TLOZ/FocusStack"
require "TLOZ/RadialSlice"
require "TLOZ/Strings_PT"
package.loaded["TLOZ/RadialHub"] = nil
require "TLOZ/RadialHub"
package.loaded["TLOZ/RadialSatellites"] = nil
require "TLOZ/RadialSatellites"

local function sliceIds(slices)
  local ids = {}
  for i = 1, #slices do ids[#ids + 1] = slices[i].id end
  return ids
end

local food = { isFood = function() return true end }
local rock = { isFood = function() return false end }

local foodSlices = TLOZ.RadialSatellites.buildItemSlices(food)
assert(#foodSlices <= 8, "max eight item verbs")
local foodIds = sliceIds(foodSlices)
assert(foodIds[1] == "eat" or table.concat(foodIds, ","):find("eat"), "food has eat")
for _, s in ipairs(foodSlices) do
  assert(not string.find(s.label, "getFullType", 1, true), "not loot browser")
  assert(s.label == TLOZ.Strings.actionEat or s.label == TLOZ.Strings.actionEquip
    or s.label == TLOZ.Strings.actionDrop or s.label == TLOZ.Strings.actionInfo, "whitelist labels")
end

local rockSlices = TLOZ.RadialSatellites.buildItemSlices(rock)
local rockIds = sliceIds(rockSlices)
for _, id in ipairs(rockIds) do
  assert(id ~= "eat", "non-food hides eat")
end

local sqNoDoor = { getDoor = function() return nil end }
local sqDoor = {
  getDoor = function(_, i)
    return (i == 1) and { __door = true } or nil
  end,
}
assert(#TLOZ.RadialSatellites.buildWorldSlices(sqNoDoor) == 0, "no door far away")
local worldDoor = TLOZ.RadialSatellites.buildWorldSlices(sqDoor)
assert(#worldDoor >= 1 and worldDoor[1].id == "door" and worldDoor[1].label == "Porta", "door slice")

local equip = TLOZ.RadialSatellites.buildEquipSlices()
assert(#equip == 3, "three equip slots")
assert(#equip <= 8, "equip whitelist small")
for _, s in ipairs(equip) do
  assert(s.id == "primary" or s.id == "secondary" or s.id == "holster", "equip ids fixed")
  assert(not string.find(s.label, "category", 1, true), "not backpack categories")
end

TLOZ._focus = TLOZ.FocusStack.new()
TLOZ._focus:push("world")
TLOZ._legend = { setContext = function(_, ctx) TLOZ._lastLegendCtx = ctx end }

TLOZ.RadialSatellites.openEquipQuick({})
assert(TLOZ._focus:peek() == "radial_sat", "equip opens sat focus")
assert(TLOZ._satPanel and #TLOZ._satPanel.slices == 3, "equip panel slices")
assert(TLOZ._lastLegendCtx == "radial_open", "legend radial_open")
if TLOZ._satPanel.close then TLOZ._satPanel:close() end

-- Build satellite whitelist (Piso/Parede/Móveis/Defesa)
local buildOpened = {}
ISBuildWindow = {
  new = function(_, x, y, w, h, player, iso, query)
    buildOpened[#buildOpened + 1] = query
    return {
      initialise = function() end,
      addToUIManager = function() end,
      setVisible = function() end,
    }
  end,
}

TLOZ.RadialSatellites.openBuild(0)
assert(TLOZ._focus:peek() == "radial_sat", "build opens sat")
assert(TLOZ._satPanel and #TLOZ._satPanel.slices == 4, "four build categories")
local buildLabels = {}
for _, s in ipairs(TLOZ._satPanel.slices) do
  buildLabels[s.id] = s.label
  assert(not string.find(s.label, "category", 1, true), "build not backpack browser")
end
assert(buildLabels.floor == "Piso" and buildLabels.wall == "Parede", "PT build labels")
assert(buildLabels.furniture == "Móveis" and buildLabels.defense == "Defesa", "PT build labels 2")
TLOZ._satPanel.selected = 1
TLOZ._satPanel:confirm()
assert(buildOpened[1] ~= nil, "build category opens ISBuildWindow")

-- Vehicle: adjacent (outside)
local vehicleCalls = {}
local fakeVehicle = {
  getPartById = function(_, id)
    if id == "EngineDoor" or id == "TrunkDoor" then return { __part = id } end
    return nil
  end,
  getSeat = function() return 0 end,
}
ISVehicleMenu = {
  getVehicleToInteractWith = function(p) return fakeVehicle end,
  processEnter = function(p, v, seat)
    vehicleCalls[#vehicleCalls + 1] = { "enter", seat }
  end,
  onOpenDoor = function(p, part)
    vehicleCalls[#vehicleCalls + 1] = { "door", part.__part }
  end,
  onExit = function(p, seat)
    vehicleCalls[#vehicleCalls + 1] = { "exit", seat }
  end,
}

local outsidePlayer = {
  getVehicle = function() return nil end,
  getPlayerNum = function() return 0 end,
}
assert(TLOZ.RadialSatellites.canUseVehicleShortcut(outsidePlayer), "near vehicle shortcut")
assert(TLOZ.RadialSatellites.findVehicle(outsidePlayer) == fakeVehicle, "find adjacent")

TLOZ._focus:push("world")
TLOZ.RadialSatellites.openVehicle(outsidePlayer)
assert(TLOZ._focus:peek() == "radial_sat", "vehicle sat open")
local ids = sliceIds(TLOZ._satPanel.slices)
local idset = {}
for _, id in ipairs(ids) do idset[id] = true end
assert(idset.enter, "enter when outside near vehicle")
assert(idset.hood and idset.trunk, "hood/trunk when near")
assert(not idset.exit, "no exit outside")
for _, s in ipairs(TLOZ._satPanel.slices) do
  if s.id == "enter" then assert(s.label == "Entrar", "PT Entrar") end
  if s.id == "hood" then assert(s.label == "Capô", "PT Capô") end
  if s.id == "trunk" then assert(s.label == "Porta-malas", "PT Porta-malas") end
end
-- confirm enter
for i, s in ipairs(TLOZ._satPanel.slices) do
  if s.id == "enter" then TLOZ._satPanel.selected = i end
end
TLOZ._satPanel:confirm()
assert(vehicleCalls[#vehicleCalls] and vehicleCalls[#vehicleCalls][1] == "enter", "enter dispatches")

-- Vehicle: inside
local insidePlayer = {
  getVehicle = function() return fakeVehicle end,
  getPlayerNum = function() return 0 end,
}
assert(TLOZ.RadialSatellites.canUseVehicleShortcut(insidePlayer), "in vehicle shortcut")
TLOZ._focus:push("world")
TLOZ.RadialSatellites.openVehicle(insidePlayer)
ids = sliceIds(TLOZ._satPanel.slices)
idset = {}
for _, id in ipairs(ids) do idset[id] = true end
assert(idset.exit, "exit when inside")
assert(not idset.enter, "no enter when inside")
assert(idset.hood and idset.trunk, "hood/trunk inside")
for _, s in ipairs(TLOZ._satPanel.slices) do
  if s.id == "exit" then assert(s.label == "Sair", "PT Sair") end
end
if TLOZ._satPanel.close then TLOZ._satPanel:close() end

-- far from vehicle: no shortcut
ISVehicleMenu.getVehicleToInteractWith = function() return nil end
local farPlayer = {
  getVehicle = function() return nil end,
  getPlayerNum = function() return 0 end,
}
assert(not TLOZ.RadialSatellites.canUseVehicleShortcut(farPlayer), "no vehicle far away")
local farSlices = TLOZ.RadialSatellites.buildVehicleSlices(farPlayer)
assert(#farSlices == 0, "empty vehicle radial far away")
