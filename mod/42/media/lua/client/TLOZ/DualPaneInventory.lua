-- media/lua/client/TLOZ/DualPaneInventory.lua
require "TLOZ/InventoryListPane"
require "TLOZ/CategoryFilter"
require "TLOZ/Strings_PT"
require "TLOZ/DualSenseHooks"

TLOZ = TLOZ or {}
TLOZ.DualPaneInventory = ISPanel:derive("TLOZ.DualPaneInventory")

function TLOZ.DualPaneInventory:new(playerNum)
  local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
  local w, h = math.floor(sw * 0.8), math.floor(sh * 0.7)
  local o = ISPanel:new(math.floor((sw - w) / 2), math.floor((sh - h) / 2), w, h)
  setmetatable(o, self)
  self.__index = self
  o.playerNum = playerNum or 0
  o.side = "you"
  o.youTab = "equipped"
  o.categoryId = "weapons"
  o.reachIndex = 1
  o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.75 }
  return o
end

function TLOZ.DualPaneInventory:open()
  local half = math.floor(self.width / 2) - 8
  self.youPane = TLOZ.InventoryListPane:new(8, 8, half, self.height - 16, TLOZ.Strings.you)
  self.reachPane = TLOZ.InventoryListPane:new(half + 16, 8, half, self.height - 16, TLOZ.Strings.reach)
  self.reachPane.showCategory = true
  self:addChild(self.youPane)
  self:addChild(self.reachPane)
  self:setVisible(true)
  self:refresh()
  self:addToUIManager()
  if TLOZ.GamepadShell and TLOZ.GamepadShell.hideVanillaInventory then
    TLOZ.GamepadShell:hideVanillaInventory(self.playerNum)
  end
  if TLOZ._focus then
    TLOZ._focus:push("dualpane")
  end
  if TLOZ._legend then
    TLOZ._legend:setContext("dualpane_you", TLOZ._glyphFamily or "xbox")
  end
  if JoypadState and JoypadState.players then
    local idx = self.playerNum + 1
    if JoypadState.players[idx] then
      JoypadState.players[idx].focus = self
    end
  end
end

function TLOZ.DualPaneInventory:close()
  if TLOZ._itemDualSenseActive and TLOZ.DualSenseHooks then
    TLOZ.DualSenseHooks.onHoldEnd("item_radial")
    TLOZ._itemDualSenseActive = false
  end
  self:setVisible(false)
  self:removeFromUIManager()
  if TLOZ._focus and TLOZ._focus:peek() == "dualpane" then
    TLOZ._focus:pop()
  end
  if TLOZ._legend then
    TLOZ._legend:setContext("world", TLOZ._glyphFamily or "xbox")
  end
  if JoypadState and JoypadState.players then
    local idx = self.playerNum + 1
    if JoypadState.players[idx] and JoypadState.players[idx].focus == self then
      JoypadState.players[idx].focus = nil
    end
  end
end

function TLOZ.DualPaneInventory:refresh()
  local player = getSpecificPlayer(self.playerNum)
  if not player then return end
  if self.youTab == "equipped" then
    self.youPane.showCategory = false
    self.youPane.title = TLOZ.Strings.you .. " — " .. TLOZ.Strings.tabEquipped
    local rows = {}
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    rows[#rows + 1] = {
      label = primary and primary:getDisplayName() or "(mão primária vazia)",
      item = primary,
      kind = "hand",
    }
    rows[#rows + 1] = {
      label = secondary and secondary:getDisplayName() or "(mão secundária vazia)",
      item = secondary,
      kind = "hand",
    }
    self.youPane:setRows(rows)
  else
    self.youPane.showCategory = true
    self.youPane.categoryId = self.categoryId
    self.youPane.title = TLOZ.Strings.you .. " — " .. TLOZ.Strings.tabBackpack
    local items = {}
    local inv = player:getInventory():getItems()
    for i = 0, inv:size() - 1 do
      local it = inv:get(i)
      items[#items + 1] = { type = it:getFullType(), label = it:getDisplayName(), item = it }
    end
    self.youPane:setRows(TLOZ.CategoryFilter.filter(items, self.categoryId))
  end
  self.reachPane.categoryId = self.categoryId
  self.reachPane.title = TLOZ.Strings.reach
  self.reachPane:setRows(self:_gatherReachRows(player))
  local inv = player:getInventory()
  self.youPane.capacityText = string.format("%.1f / %.1f kg", inv:getCapacityWeight(), inv:getMaxWeight())
end

function TLOZ.DualPaneInventory:_gatherReachRows(player)
  local rows = {}
  local sq = player:getCurrentSquare()
  if not sq then
    return { { label = "(sem alcance)", item = nil } }
  end
  local witems = sq:getWorldObjects()
  if witems then
    for i = 0, witems:size() - 1 do
      local wo = witems:get(i)
      local item = wo:getItem()
      if item then
        rows[#rows + 1] = {
          type = item:getFullType(),
          label = item:getDisplayName(),
          item = item,
          world = true,
        }
      end
    end
  end
  if #rows == 0 then
    rows[1] = { label = "(vazio)", item = nil }
  end
  return TLOZ.CategoryFilter.filter(rows, self.categoryId)
end

function TLOZ.DualPaneInventory:onSwapSide()
  self.side = (self.side == "you") and "reach" or "you"
  if TLOZ._legend then
    local ctx = (self.side == "you") and "dualpane_you" or "dualpane_reach"
    TLOZ._legend:setContext(ctx, TLOZ._glyphFamily or "xbox")
  end
end

function TLOZ.DualPaneInventory:onTabOrCycle(delta)
  if self.side == "you" then
    if self.youTab == "equipped" then
      self.youTab = "backpack"
    else
      self.youTab = "equipped"
    end
  else
    self.reachIndex = math.max(1, self.reachIndex + (delta >= 0 and 1 or -1))
  end
  self:refresh()
end

function TLOZ.DualPaneInventory:onCycleCategory(delta)
  if self.side == "you" and self.youTab ~= "backpack" then return end
  self.categoryId = TLOZ.CategoryFilter.cycle(self.categoryId, delta)
  self:refresh()
end

function TLOZ.DualPaneInventory:onNavigate(delta)
  if self.side == "you" then
    self.youPane:moveSelection(delta)
  else
    self.reachPane:moveSelection(delta)
  end
end

function TLOZ.DualPaneInventory:getSelectedItem()
  local pane = (self.side == "you") and self.youPane or self.reachPane
  if not pane then return nil end
  local row = pane:getSelected()
  return row and row.item
end

function TLOZ.DualPaneInventory:onConfirmTransfer()
  local player = getSpecificPlayer(self.playerNum)
  if not player then return end
  local srcPane = (self.side == "you") and self.youPane or self.reachPane
  local dstIsPlayer = self.side == "reach"
  local row = srcPane:getSelected()
  if not row or not row.item then return end
  if dstIsPlayer then
    ISTimedActionQueue.add(ISInventoryTransferAction:new(
      player,
      row.item,
      row.item:getContainer(),
      player:getInventory()
    ))
  else
    player:getCurrentSquare():AddWorldInventoryItem(row.item, 0, 0, 0)
    player:getInventory():Remove(row.item)
  end
  self:refresh()
end

local function joyButton(name, fallback)
  if Joypad and Joypad[name] then return Joypad[name] end
  return fallback
end

function TLOZ.DualPaneInventory:onJoypadDir(dir)
  if dir == Joypad.UP or dir == "up" then
    self:onNavigate(-1)
  elseif dir == Joypad.DOWN or dir == "down" then
    self:onNavigate(1)
  elseif dir == Joypad.LEFT or dir == "left" then
    self:onCycleCategory(-1)
  elseif dir == Joypad.RIGHT or dir == "right" then
    self:onCycleCategory(1)
  end
end

function TLOZ.DualPaneInventory:onJoypadDown(button)
  local Y = joyButton("YButton", 3)
  local B = joyButton("BButton", 1)
  local X = joyButton("XButton", 2)
  local A = joyButton("AButton", 0)
  local LB = joyButton("LBumper", 4)
  local RB = joyButton("RBumper", 5)

  if button == Y or button == B then
    if TLOZ.closeDualPane then TLOZ.closeDualPane(self.playerNum) end
    return true
  end
  if button == X then
    self:onSwapSide()
    return true
  end
  if button == LB then
    self:onTabOrCycle(-1)
    return true
  end
  if button == RB then
    self:onTabOrCycle(1)
    return true
  end
  if button == A then
    self:onConfirmTransfer()
    return true
  end
  return false
end
