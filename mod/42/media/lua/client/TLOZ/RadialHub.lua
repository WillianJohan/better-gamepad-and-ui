-- media/lua/client/TLOZ/RadialHub.lua
require "TLOZ/RadialSlice"
require "TLOZ/Strings_PT"
require "TLOZ/DualSenseHooks"

TLOZ = TLOZ or {}
TLOZ.RadialHub = ISPanel:derive("TLOZ.RadialHub")

function TLOZ.RadialHub:new()
  local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
  local size = 280
  local o = ISPanel:new(math.floor((sw - size) / 2), math.floor((sh - size) / 2), size, size)
  setmetatable(o, self)
  self.__index = self
  o.selected = 1
  o.slices = {}
  o.playerNum = 0
  return o
end

function TLOZ.RadialHub:_candidates()
  local S = TLOZ.Strings
  return {
    { id = "inventory", label = S.radialInventory, enabled = true },
    { id = "health", label = S.radialHealth, enabled = true },
    { id = "map", label = S.radialMap, enabled = true },
    { id = "craft", label = S.radialCraft, enabled = true },
    { id = "build", label = S.radialBuild, enabled = true },
    { id = "character", label = S.radialCharacter, enabled = true },
    { id = "options", label = S.radialOptions, enabled = true },
  }
end

function TLOZ.RadialHub:open()
  self.slices = TLOZ.RadialSlice.build(self:_candidates())
  self.selected = 1
  self:addToUIManager()
  if TLOZ._focus then TLOZ._focus:push("radial_hub") end
  if TLOZ._legend then TLOZ._legend:setContext("radial_open", TLOZ._glyphFamily or "xbox") end
  if JoypadState and JoypadState.players then
    local idx = (self.playerNum or 0) + 1
    if JoypadState.players[idx] then
      JoypadState.players[idx].focus = self
    end
  end
end

function TLOZ.RadialHub:close()
  if TLOZ._hubDualSenseActive and TLOZ.DualSenseHooks then
    TLOZ.DualSenseHooks.onHoldEnd("hub")
    TLOZ._hubDualSenseActive = false
  end
  self:removeFromUIManager()
  if TLOZ._focus and TLOZ._focus:peek() == "radial_hub" then TLOZ._focus:pop() end
  if TLOZ._legend then TLOZ._legend:setContext("world", TLOZ._glyphFamily or "xbox") end
  if JoypadState and JoypadState.players then
    local idx = (self.playerNum or 0) + 1
    if JoypadState.players[idx] and JoypadState.players[idx].focus == self then
      JoypadState.players[idx].focus = nil
    end
  end
end

function TLOZ.RadialHub:setStickDirection(angleRad)
  if #self.slices == 0 then return end
  local n = #self.slices
  local sector = (math.pi * 2) / n
  local angle = angleRad + math.pi / 2
  while angle < 0 do angle = angle + math.pi * 2 end
  while angle >= math.pi * 2 do angle = angle - math.pi * 2 end
  local idx = math.floor((angle + sector / 2) / sector) % n
  self.selected = idx + 1
end

local function playerInfoPanel(player)
  if not player then return nil end
  local n = player.getPlayerNum and player:getPlayerNum() or 0
  if getPlayerInfoPanel then
    local panel = getPlayerInfoPanel(n)
    if panel then return panel end
  end
  if getPlayerData then
    local data = getPlayerData(n)
    if data and data.characterInfo then return data.characterInfo end
  end
  if ISCharacterInfoWindow and ISCharacterInfoWindow.instance then
    return ISCharacterInfoWindow.instance
  end
  return nil
end

local function viewName(key, fallback)
  if xpSystemText and xpSystemText[key] then return xpSystemText[key] end
  return fallback
end

function TLOZ.RadialHub:_openVanillaSlice(sliceId, player)
  if not player then return end
  local playerNum = player.getPlayerNum and player:getPlayerNum() or 0

  if sliceId == "health" then
    local info = playerInfoPanel(player)
    if info and info.toggleView then
      info:toggleView(viewName("health", "Health"))
    elseif ISHealthPanel and ISHealthPanel.activate then
      ISHealthPanel.activate(player)
    end
    return
  end

  if sliceId == "map" then
    if ISWorldMap and ISWorldMap.ToggleWorldMap then
      ISWorldMap.ToggleWorldMap(playerNum)
    elseif ISWorldMap and ISWorldMap.ShowWorldMap then
      ISWorldMap.ShowWorldMap(playerNum)
    elseif player.setMapVisible then
      player:setMapVisible(not player:isMapVisible())
    end
    return
  end

  if sliceId == "craft" then
    if ISCraftingUI and ISCraftingUI.toggleCraftingUI then
      ISCraftingUI.toggleCraftingUI()
    elseif getPlayerCraftingUI then
      local ui = getPlayerCraftingUI(playerNum)
      if ui then
        if ui.setVisible then ui:setVisible(true) end
        if ui.addToUIManager then ui:addToUIManager() end
      end
    end
    return
  end

  if sliceId == "character" then
    local info = playerInfoPanel(player)
    if info and info.toggleView then
      info:toggleView(viewName("skills", viewName("character", "Skills")))
    elseif ISCharacterInfoWindow and ISCharacterInfoWindow.toggleCharacterInfoWindow then
      ISCharacterInfoWindow.toggleCharacterInfoWindow(player)
    end
    return
  end

  if sliceId == "options" then
    if MainScreen and MainScreen.instance then
      local ms = MainScreen.instance
      if ms.getIsVisible and ms.setVisible then
        ms:setVisible(not ms:getIsVisible())
      elseif ms.setVisible then
        ms:setVisible(true)
      end
      if ms.mainOptions and ms.mainOptions.setVisible then
        ms.mainOptions:setVisible(true)
      end
    elseif MainOptions and MainOptions.instance and MainOptions.instance.setVisible then
      MainOptions.instance:setVisible(true)
    end
  end
end

function TLOZ.RadialHub:confirm()
  local slice = self.slices[self.selected]
  self:close()
  if not slice then return end
  if slice.id == "inventory" then
    if TLOZ.openDualPane then TLOZ.openDualPane(self.playerNum or 0) end
  elseif slice.id == "build" then
    if TLOZ.RadialSatellites and TLOZ.RadialSatellites.openBuild then
      TLOZ.RadialSatellites.openBuild(self.playerNum or 0)
    end
  else
    local player = getSpecificPlayer(self.playerNum or 0)
    self:_openVanillaSlice(slice.id, player)
  end
end

function TLOZ.RadialHub:prerender()
  self:drawRect(0, 0, self.width, self.height, 0.7, 0.02, 0.02, 0.02)
  local cx, cy = self.width / 2, self.height / 2
  for i = 1, #self.slices do
    local a = ((i - 1) / #self.slices) * math.pi * 2 - math.pi / 2
    local x = cx + math.cos(a) * 90
    local y = cy + math.sin(a) * 90
    local c = (i == self.selected) and 1 or 0.6
    self:drawTextCentre(self.slices[i].label, x, y, c, c, c, 1, UIFont.Small)
  end
end

local function joyButton(name, fallback)
  if Joypad and Joypad[name] then return Joypad[name] end
  return fallback
end

function TLOZ.RadialHub:onJoypadDown(button)
  local B = joyButton("BButton", 1)
  local A = joyButton("AButton", 0)
  if button == B then
    self:close()
    return true
  end
  if button == A then
    self:confirm()
    return true
  end
  return false
end
