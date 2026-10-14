-- media/lua/client/BGUI/GamepadShell.lua
require "BGUI/FocusStack"
require "BGUI/RadialHub"
require "BGUI/DualSenseHooks"
BGUI = BGUI or {}
BGUI.GamepadShell = {}
BGUI._hubHoldMs = 0
BGUI._hubOpenedThisPress = false
BGUI._hubDualSenseActive = false
BGUI._itemRadialHoldMs = 0
BGUI._itemRadialOpened = false
BGUI._itemDualSenseActive = false
BGUI._worldRadialHoldMs = 0
BGUI._worldRadialOpened = false
BGUI._equipRadialHoldMs = 0
BGUI._equipRadialOpened = false

local function dualSenseStart(kind)
  if BGUI.DualSenseHooks and BGUI.DualSenseHooks.onHoldStart then
    BGUI.DualSenseHooks.onHoldStart(kind)
  end
end

local function dualSenseEnd(kind)
  if BGUI.DualSenseHooks and BGUI.DualSenseHooks.onHoldEnd then
    BGUI.DualSenseHooks.onHoldEnd(kind)
  end
end

local function hideInvPage(page)
  if not page then return end
  if page.setVisible then page:setVisible(false) end
  if page.setIsVisible then page:setIsVisible(false) end
  if page.removeFromUIManager then page:removeFromUIManager() end
end

function BGUI.GamepadShell:hideVanillaInventory(playerNum)
  local n = getNumActivePlayers and getNumActivePlayers() or 1
  for i = 0, n - 1 do
    if playerNum == nil or i == playerNum then
      if getPlayerInventory then
        hideInvPage(getPlayerInventory(i))
      end
      if getPlayerLoot then
        hideInvPage(getPlayerLoot(i))
      end
    end
  end
end

function BGUI.GamepadShell:restoreVanillaInventory()
  -- Não reabre inventário automaticamente; vanilla volta no próximo toggle KBM.
end

function BGUI.GamepadShell:activate()
  BGUI._activeShell = "gamepad"
  BGUI._focus = BGUI._focus or BGUI.FocusStack.new()
  BGUI._focus:clear()
  BGUI._focus:push("world")
  self:hideVanillaInventory()
  if Events and Events.OnTick and not BGUI._vanillaInvGuard then
    BGUI._vanillaInvGuard = function()
      if BGUI._activeShell ~= "gamepad" then return end
      BGUI.GamepadShell:hideVanillaInventory()
    end
    Events.OnTick.Add(BGUI._vanillaInvGuard)
  end
  if BGUI.ButtonLegend and not BGUI._legend then
    BGUI._legend = BGUI.ButtonLegend:new(0, getCore():getScreenHeight() - 32, getCore():getScreenWidth(), 32)
    BGUI._legend:setContext("world", BGUI._glyphFamily or "xbox")
    BGUI._legend:addToUIManager()
  end
end

local function joyButton(name, fallback)
  if Joypad and Joypad[name] then return Joypad[name] end
  return fallback
end

local LB = joyButton("LBumper", 4)
local LT = joyButton("LeftTrigger", 6)
local RT = joyButton("RightTrigger", 7)
local A = joyButton("AButton", 0)

function BGUI.GamepadShell:_buttonHeld(playerNum, testKey, joyName, fallback, joyField)
  if BGUI[testKey] ~= nil then return BGUI[testKey] end
  local idx = (playerNum or 0) + 1
  if not JoypadState or not JoypadState.players then return false end
  local j = JoypadState.players[idx]
  if not j then return false end
  if joyField and j[joyField] then return j[joyField] end
  if j.controller and j.controller.isButtonPressed then
    return j.controller:isButtonPressed(joyButton(joyName, fallback))
  end
  return false
end

function BGUI.GamepadShell:_lbHeld(playerNum)
  if BGUI._testLbHeld ~= nil then return BGUI._testLbHeld end
  local idx = (playerNum or 0) + 1
  if not JoypadState or not JoypadState.players then return false end
  local j = JoypadState.players[idx]
  if not j then return false end
  if j.isLBPressed then return j.isLBPressed end
  if j.controller and j.controller.isButtonPressed then
    return j.controller:isButtonPressed(LB)
  end
  return false
end

function BGUI.GamepadShell:_ltHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testLtHeld", "LeftTrigger", 6, "isLTPressed")
end

function BGUI.GamepadShell:_rtHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testRtHeld", "RightTrigger", 7, "isRTPressed")
end

function BGUI.GamepadShell:_confirmHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testConfirmHeld", "AButton", 0, "isAPressed")
end

function BGUI.GamepadShell:_yHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testYHeld", "YButton", 3, "isYPressed")
end

function BGUI.GamepadShell:_satHoldReleased(playerNum)
  local kind = BGUI._satHoldKind
  if kind == "lt" then return not self:_ltHeld(playerNum) end
  if kind == "rt" then return not self:_rtHeld(playerNum) end
  if kind == "confirm" then return not self:_confirmHeld(playerNum) end
  return false
end

function BGUI.GamepadShell:_tickDelta()
  local dt = 16
  if UIManager and UIManager.getMillisDelta then
    dt = UIManager.getMillisDelta() or dt
  end
  return dt
end

function BGUI.GamepadShell:_stickAngle(playerNum)
  local idx = (playerNum or 0) + 1
  if not JoypadState or not JoypadState.players then return nil end
  local j = JoypadState.players[idx]
  if not j then return nil end
  local x = j.x or j.lx or 0
  local y = j.y or j.ly or 0
  if (x * x + y * y) < 0.04 then return nil end
  return math.atan2(y, x)
end

function BGUI.GamepadShell:tickSatellites(playerNum)
  if BGUI._activeShell ~= "gamepad" then return end
  if not BGUI._router or BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then return end
  if not BGUI.RadialSatellites then return end
  playerNum = playerNum or 0

  if BGUI._satPanel and BGUI._focus and BGUI._focus:peek() == "radial_sat" then
    local angle = self:_stickAngle(playerNum)
    if angle then BGUI._satPanel:setStickDirection(angle) end
    if self:_satHoldReleased(playerNum) then
      if BGUI._satHoldKind == "lt" and BGUI._itemDualSenseActive then
        dualSenseEnd("item_radial")
        BGUI._itemDualSenseActive = false
      end
      BGUI._satPanel:close()
    end
    return
  end

  local focus = BGUI._focus and BGUI._focus:peek()
  if focus == "dualpane" and BGUI._dualPane then
    if self:_ltHeld(playerNum) then
      if not BGUI._itemDualSenseActive then
        dualSenseStart("item_radial")
        BGUI._itemDualSenseActive = true
      end
      BGUI._itemRadialHoldMs = BGUI._itemRadialHoldMs + self:_tickDelta()
      if not BGUI._itemRadialOpened and BGUI._itemRadialHoldMs >= 250 then
        local item = BGUI._dualPane.getSelectedItem and BGUI._dualPane:getSelectedItem()
        if item then
          BGUI.RadialSatellites.openItem(item, BGUI._dualPane.playerNum)
        end
        BGUI._itemRadialOpened = true
      end
    else
      if BGUI._itemDualSenseActive then
        dualSenseEnd("item_radial")
        BGUI._itemDualSenseActive = false
      end
      BGUI._itemRadialHoldMs = 0
      BGUI._itemRadialOpened = false
    end
    return
  end

  if focus ~= "world" then
    BGUI._worldRadialHoldMs = 0
    BGUI._worldRadialOpened = false
    BGUI._equipRadialHoldMs = 0
    BGUI._equipRadialOpened = false
    return
  end

  local player = getSpecificPlayer(playerNum)
  if not player then return end

  if self:_confirmHeld(playerNum) then
    BGUI._worldRadialHoldMs = BGUI._worldRadialHoldMs + self:_tickDelta()
    if not BGUI._worldRadialOpened and BGUI._worldRadialHoldMs >= 250 then
      -- Perto/dentro de veículo: atalho Veículo; senão radial de mundo (porta/etc.)
      if BGUI.RadialSatellites.canUseVehicleShortcut
          and BGUI.RadialSatellites.canUseVehicleShortcut(player) then
        BGUI.RadialSatellites.openVehicle(player)
      else
        BGUI.RadialSatellites.openWorld(player:getCurrentSquare(), player)
      end
      BGUI._worldRadialOpened = true
    end
  else
    BGUI._worldRadialHoldMs = 0
    BGUI._worldRadialOpened = false
  end

  if self:_rtHeld(playerNum) then
    BGUI._equipRadialHoldMs = BGUI._equipRadialHoldMs + self:_tickDelta()
    if not BGUI._equipRadialOpened and BGUI._equipRadialHoldMs >= 250 then
      BGUI.RadialSatellites.openEquipQuick(player)
      BGUI._equipRadialOpened = true
    end
  else
    BGUI._equipRadialHoldMs = 0
    BGUI._equipRadialOpened = false
  end
end

function BGUI.GamepadShell:tickHub(playerNum)
  if BGUI._activeShell ~= "gamepad" then return end
  if not BGUI._router or BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then return end
  playerNum = playerNum or 0

  if BGUI._radialHub and BGUI._focus and BGUI._focus:peek() == "radial_hub" then
    local angle = self:_stickAngle(playerNum)
    if angle then BGUI._radialHub:setStickDirection(angle) end
    if not self:_lbHeld(playerNum) then
      if BGUI._hubDualSenseActive then
        dualSenseEnd("hub")
        BGUI._hubDualSenseActive = false
      end
      BGUI._radialHub:close()
      BGUI._radialHub = nil
      BGUI._hubOpenedThisPress = false
      BGUI._hubHoldMs = 0
    end
    return
  end

  if not BGUI._focus or BGUI._focus:peek() ~= "world" then
    if BGUI._hubDualSenseActive then
      dualSenseEnd("hub")
      BGUI._hubDualSenseActive = false
    end
    BGUI._hubHoldMs = 0
    BGUI._hubOpenedThisPress = false
    return
  end

  if self:_lbHeld(playerNum) then
    if not BGUI._hubDualSenseActive then
      dualSenseStart("hub")
      BGUI._hubDualSenseActive = true
    end
    local dt = 16
    if UIManager and UIManager.getMillisDelta then
      dt = UIManager.getMillisDelta() or dt
    end
    BGUI._hubHoldMs = BGUI._hubHoldMs + dt
    if not BGUI._hubOpenedThisPress and BGUI._hubHoldMs >= 250 then
      BGUI._radialHub = BGUI.RadialHub:new()
      BGUI._radialHub.playerNum = playerNum
      BGUI._radialHub:open()
      BGUI._hubOpenedThisPress = true
    end
  else
    if BGUI._hubDualSenseActive then
      dualSenseEnd("hub")
      BGUI._hubDualSenseActive = false
    end
    BGUI._hubHoldMs = 0
    BGUI._hubOpenedThisPress = false
  end
end

function BGUI.GamepadShell:deactivate()
  if BGUI._legend then
    BGUI._legend:removeFromUIManager()
    BGUI._legend = nil
  end
  if BGUI._dualPane then
    BGUI._dualPane:close()
    BGUI._dualPane = nil
  end
  if BGUI._hubDualSenseActive then
    dualSenseEnd("hub")
    BGUI._hubDualSenseActive = false
  end
  if BGUI._itemDualSenseActive then
    dualSenseEnd("item_radial")
    BGUI._itemDualSenseActive = false
  end
  if BGUI._radialHub then
    BGUI._radialHub:close()
    BGUI._radialHub = nil
  end
  if BGUI._satPanel then
    BGUI._satPanel:close()
    BGUI._satPanel = nil
  end
  if BGUI._focus then BGUI._focus:clear() end
  BGUI._activeShell = "kbm"
end
