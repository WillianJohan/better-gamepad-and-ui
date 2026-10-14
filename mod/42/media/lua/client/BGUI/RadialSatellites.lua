-- media/lua/client/BGUI/RadialSatellites.lua
require "BGUI/RadialSlice"
require "BGUI/Strings_PT"
require "BGUI/RadialHub"

BGUI = BGUI or {}
BGUI.RadialSatellites = {}

function BGUI.RadialSatellites.buildItemSlices(item)
  local S = BGUI.Strings
  local canEat = item and item.isFood and item:isFood()
  return BGUI.RadialSlice.build({
    { id = "eat", label = S.actionEat, enabled = canEat },
    { id = "equip", label = S.actionEquip, enabled = item ~= nil },
    { id = "drop", label = S.actionDrop, enabled = item ~= nil },
    { id = "info", label = S.actionInfo, enabled = item ~= nil },
  })
end

function BGUI.RadialSatellites.scanWorldFlags(square)
  local hasDoor, hasWindow, hasBody, hasStove = false, false, false, false
  if square then
    for i = 0, 3 do
      local door = square:getDoor(i)
      if door then hasDoor = true end
    end
  end
  return hasDoor, hasWindow, hasBody, hasStove
end

function BGUI.RadialSatellites.buildWorldSlices(square)
  local hasDoor, hasWindow, hasBody, hasStove = BGUI.RadialSatellites.scanWorldFlags(square)
  return BGUI.RadialSlice.build({
    { id = "door", label = "Porta", enabled = hasDoor },
    { id = "window", label = "Janela", enabled = hasWindow },
    { id = "body", label = "Corpo", enabled = hasBody },
    { id = "stove", label = "Fogão", enabled = hasStove },
  })
end

function BGUI.RadialSatellites.buildEquipSlices()
  return BGUI.RadialSlice.build({
    { id = "primary", label = "Mão primária", enabled = true },
    { id = "secondary", label = "Mão secundária", enabled = true },
    { id = "holster", label = "Arma rápida", enabled = true },
  })
end

local function closeSatPanel(panel)
  if BGUI._satHoldKind == "lt" and BGUI._itemDualSenseActive and BGUI.DualSenseHooks then
    BGUI.DualSenseHooks.onHoldEnd("item_radial")
    BGUI._itemDualSenseActive = false
  end
  panel:removeFromUIManager()
  if BGUI._focus and BGUI._focus:peek() == "radial_sat" then
    BGUI._focus:pop()
  end
  if BGUI._legend then
    local ctx = "world"
    if BGUI._focus and BGUI._focus:peek() == "dualpane" and BGUI._dualPane then
      ctx = (BGUI._dualPane.side == "reach") and "dualpane_reach" or "dualpane_you"
    end
    BGUI._legend:setContext(ctx, BGUI._glyphFamily or "xbox")
  end
  if JoypadState and JoypadState.players and panel.playerNum ~= nil then
    local idx = panel.playerNum + 1
    if JoypadState.players[idx] and JoypadState.players[idx].focus == panel then
      JoypadState.players[idx].focus = nil
    end
  end
  if BGUI._satPanel == panel then
    BGUI._satPanel = nil
    BGUI._satHoldKind = nil
  end
end

local function openSlicePanel(slices, onPick, holdKind, playerNum)
  if not slices or #slices == 0 then return end
  local panel = BGUI.RadialHub:new()
  panel.playerNum = playerNum or 0
  panel.slices = slices
  panel.selected = 1
  panel.close = function(self)
    closeSatPanel(self)
  end
  panel.confirm = function(self)
    local s = self.slices[self.selected]
    closeSatPanel(self)
    if s and onPick then onPick(s.id) end
  end
  panel:addToUIManager()
  if BGUI._focus then BGUI._focus:push("radial_sat") end
  if BGUI._legend then BGUI._legend:setContext("radial_open", BGUI._glyphFamily or "xbox") end
  if JoypadState and JoypadState.players then
    local idx = panel.playerNum + 1
    if JoypadState.players[idx] then
      JoypadState.players[idx].focus = panel
    end
  end
  BGUI._satPanel = panel
  BGUI._satHoldKind = holdKind
end

function BGUI.RadialSatellites.openItem(item, playerNum)
  if not item then return end
  local S = BGUI.Strings
  local slices = BGUI.RadialSatellites.buildItemSlices(item)
  openSlicePanel(slices, function(id)
    local player = getSpecificPlayer(playerNum or 0)
    if not player or not item then return end
    if id == "eat" and ISEatFoodAction then
      ISTimedActionQueue.add(ISEatFoodAction:new(player, item, 100))
    end
    if id == "equip" and ISEquipWeaponAction then
      ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 50, true, false))
    end
    if id == "drop" then
      local sq = player:getCurrentSquare()
      if sq then sq:AddWorldInventoryItem(item, 0, 0, 0) end
      player:getInventory():Remove(item)
    end
    if BGUI._dualPane then BGUI._dualPane:refresh() end
  end, "lt", playerNum)
end

local function playerNumOf(player, fallback)
  if player and player.getPlayerNum then return player:getPlayerNum() end
  return fallback or 0
end

function BGUI.RadialSatellites.openWorld(square, player)
  if not player then return end
  local sq = square or player:getCurrentSquare()
  local slices = BGUI.RadialSatellites.buildWorldSlices(sq)
  openSlicePanel(slices, function(_id)
    -- despacho vanilla (porta/janela/etc.) numa task futura
  end, "confirm", playerNumOf(player))
end

function BGUI.RadialSatellites.openEquipQuick(player)
  if not player then return end
  local slices = BGUI.RadialSatellites.buildEquipSlices()
  openSlicePanel(slices, function(_id)
    -- troca rápida: lista curta (não browser radial de categorias)
  end, "rt", playerNumOf(player))
end

local BUILD_QUERY = {
  floor = "Floor",
  wall = "Wall",
  furniture = "Furniture",
  defense = "Defense",
}

function BGUI.RadialSatellites.buildBuildSlices()
  return BGUI.RadialSlice.build({
    { id = "floor", label = "Piso", enabled = true },
    { id = "wall", label = "Parede", enabled = true },
    { id = "furniture", label = "Móveis", enabled = true },
    { id = "defense", label = "Defesa", enabled = true },
  })
end

local function openBuildWindow(player, query)
  if not player then return end
  if not ISBuildWindow or not ISBuildWindow.new then return end
  local core = getCore and getCore()
  local sw = core and core.getScreenWidth and core:getScreenWidth() or 800
  local sh = core and core.getScreenHeight and core:getScreenHeight() or 600
  local w, h = 460, 520
  local x = math.floor((sw - w) / 2)
  local y = math.floor((sh - h) / 2)
  local ui = ISBuildWindow:new(x, y, w, h, player, nil, query)
  if ui.initialise then ui:initialise() end
  if ui.addToUIManager then ui:addToUIManager() end
  if ui.setVisible then ui:setVisible(true) end
  if JoypadState and JoypadState.players and player.getPlayerNum then
    local idx = player:getPlayerNum() + 1
    if JoypadState.players[idx] then
      JoypadState.players[idx].focus = ui
    end
  end
end

function BGUI.RadialSatellites.openBuild(playerNum)
  playerNum = playerNum or 0
  local slices = BGUI.RadialSatellites.buildBuildSlices()
  openSlicePanel(slices, function(id)
    local player = getSpecificPlayer(playerNum)
    openBuildWindow(player, BUILD_QUERY[id] or id)
  end, "confirm", playerNum)
end

function BGUI.RadialSatellites.findVehicle(player)
  if not player then return nil end
  local v = player.getVehicle and player:getVehicle() or nil
  if v then return v end
  if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
    return ISVehicleMenu.getVehicleToInteractWith(player)
  end
  return nil
end

function BGUI.RadialSatellites.canUseVehicleShortcut(player)
  return BGUI.RadialSatellites.findVehicle(player) ~= nil
end

function BGUI.RadialSatellites.buildVehicleSlices(player)
  if not player then return {} end
  local vehicle = BGUI.RadialSatellites.findVehicle(player)
  local inside = player.getVehicle and player:getVehicle() ~= nil
  local near = vehicle ~= nil
  local hasHood = false
  local hasTrunk = false
  if vehicle and vehicle.getPartById then
    hasHood = vehicle:getPartById("EngineDoor") ~= nil
    hasTrunk = vehicle:getPartById("TrunkDoor") ~= nil
  end
  return BGUI.RadialSlice.build({
    { id = "enter", label = "Entrar", enabled = near and not inside },
    { id = "exit", label = "Sair", enabled = inside },
    { id = "hood", label = "Capô", enabled = near and hasHood },
    { id = "trunk", label = "Porta-malas", enabled = near and hasTrunk },
  })
end

local function dispatchVehicle(player, id)
  if not player or not ISVehicleMenu then return end
  local vehicle = BGUI.RadialSatellites.findVehicle(player)
  if not vehicle then return end
  if id == "enter" and ISVehicleMenu.processEnter then
    ISVehicleMenu.processEnter(player, vehicle, 0)
  elseif id == "enter" and ISVehicleMenu.onEnter then
    ISVehicleMenu.onEnter(player, vehicle, 0)
  elseif id == "exit" and ISVehicleMenu.onExit then
    local seat = nil
    if vehicle.getSeat then seat = vehicle:getSeat(player) end
    ISVehicleMenu.onExit(player, seat)
  elseif id == "hood" and ISVehicleMenu.onOpenDoor and vehicle.getPartById then
    local part = vehicle:getPartById("EngineDoor")
    if part then ISVehicleMenu.onOpenDoor(player, part) end
  elseif id == "trunk" and ISVehicleMenu.onOpenDoor and vehicle.getPartById then
    local part = vehicle:getPartById("TrunkDoor")
    if part then ISVehicleMenu.onOpenDoor(player, part) end
  end
end

function BGUI.RadialSatellites.openVehicle(player)
  if not player then return end
  local slices = BGUI.RadialSatellites.buildVehicleSlices(player)
  openSlicePanel(slices, function(id)
    dispatchVehicle(player, id)
  end, "confirm", playerNumOf(player))
end
