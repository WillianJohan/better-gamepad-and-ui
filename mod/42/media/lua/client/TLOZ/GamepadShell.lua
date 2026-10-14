-- media/lua/client/TLOZ/GamepadShell.lua
require "TLOZ/FocusStack"
require "TLOZ/RadialHub"
require "TLOZ/DualSenseHooks"
TLOZ = TLOZ or {}
TLOZ.GamepadShell = {}
TLOZ._hubHoldMs = 0
TLOZ._hubOpenedThisPress = false
TLOZ._hubDualSenseActive = false
TLOZ._itemRadialHoldMs = 0
TLOZ._itemRadialOpened = false
TLOZ._itemDualSenseActive = false
TLOZ._worldRadialHoldMs = 0
TLOZ._worldRadialOpened = false
TLOZ._equipRadialHoldMs = 0
TLOZ._equipRadialOpened = false

local function dualSenseStart(kind)
  if TLOZ.DualSenseHooks and TLOZ.DualSenseHooks.onHoldStart then
    TLOZ.DualSenseHooks.onHoldStart(kind)
  end
end

local function dualSenseEnd(kind)
  if TLOZ.DualSenseHooks and TLOZ.DualSenseHooks.onHoldEnd then
    TLOZ.DualSenseHooks.onHoldEnd(kind)
  end
end

function TLOZ.GamepadShell:hideVanillaInventory(playerNum)
  if not getPlayerInventory then return end
  local n = getNumActivePlayers and getNumActivePlayers() or 1
  for i = 0, n - 1 do
    if playerNum == nil or i == playerNum then
      local page = getPlayerInventory(i)
      if page then
        if page.setVisible then page:setVisible(false) end
        if page.removeFromUIManager then page:removeFromUIManager() end
      end
    end
  end
end

function TLOZ.GamepadShell:restoreVanillaInventory()
  -- Não reabre inventário automaticamente; vanilla volta no próximo toggle KBM.
end

function TLOZ.GamepadShell:activate()
  TLOZ._activeShell = "gamepad"
  TLOZ._focus = TLOZ._focus or TLOZ.FocusStack.new()
  TLOZ._focus:clear()
  TLOZ._focus:push("world")
  self:hideVanillaInventory()
  if Events and Events.OnTick and not TLOZ._vanillaInvGuard then
    TLOZ._vanillaInvGuard = function()
      if TLOZ._activeShell ~= "gamepad" then return end
      TLOZ.GamepadShell:hideVanillaInventory()
    end
    Events.OnTick.Add(TLOZ._vanillaInvGuard)
  end
  if TLOZ.ButtonLegend and not TLOZ._legend then
    TLOZ._legend = TLOZ.ButtonLegend:new(0, getCore():getScreenHeight() - 32, getCore():getScreenWidth(), 32)
    TLOZ._legend:setContext("world", TLOZ._glyphFamily or "xbox")
    TLOZ._legend:addToUIManager()
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

function TLOZ.GamepadShell:_buttonHeld(playerNum, testKey, joyName, fallback, joyField)
  if TLOZ[testKey] ~= nil then return TLOZ[testKey] end
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

function TLOZ.GamepadShell:_lbHeld(playerNum)
  if TLOZ._testLbHeld ~= nil then return TLOZ._testLbHeld end
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

function TLOZ.GamepadShell:_ltHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testLtHeld", "LeftTrigger", 6, "isLTPressed")
end

function TLOZ.GamepadShell:_rtHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testRtHeld", "RightTrigger", 7, "isRTPressed")
end

function TLOZ.GamepadShell:_confirmHeld(playerNum)
  return self:_buttonHeld(playerNum, "_testConfirmHeld", "AButton", 0, "isAPressed")
end

function TLOZ.GamepadShell:_satHoldReleased(playerNum)
  local kind = TLOZ._satHoldKind
  if kind == "lt" then return not self:_ltHeld(playerNum) end
  if kind == "rt" then return not self:_rtHeld(playerNum) end
  if kind == "confirm" then return not self:_confirmHeld(playerNum) end
  return false
end

function TLOZ.GamepadShell:_tickDelta()
  local dt = 16
  if UIManager and UIManager.getMillisDelta then
    dt = UIManager.getMillisDelta() or dt
  end
  return dt
end

function TLOZ.GamepadShell:_stickAngle(playerNum)
  local idx = (playerNum or 0) + 1
  if not JoypadState or not JoypadState.players then return nil end
  local j = JoypadState.players[idx]
  if not j then return nil end
  local x = j.x or j.lx or 0
  local y = j.y or j.ly or 0
  if (x * x + y * y) < 0.04 then return nil end
  return math.atan2(y, x)
end

function TLOZ.GamepadShell:tickSatellites(playerNum)
  if TLOZ._activeShell ~= "gamepad" then return end
  if not TLOZ._router or TLOZ._router:getMode() ~= TLOZ.InputMode.GAMEPAD then return end
  if not TLOZ.RadialSatellites then return end
  playerNum = playerNum or 0

  if TLOZ._satPanel and TLOZ._focus and TLOZ._focus:peek() == "radial_sat" then
    local angle = self:_stickAngle(playerNum)
    if angle then TLOZ._satPanel:setStickDirection(angle) end
    if self:_satHoldReleased(playerNum) then
      if TLOZ._satHoldKind == "lt" and TLOZ._itemDualSenseActive then
        dualSenseEnd("item_radial")
        TLOZ._itemDualSenseActive = false
      end
      TLOZ._satPanel:close()
    end
    return
  end

  local focus = TLOZ._focus and TLOZ._focus:peek()
  if focus == "dualpane" and TLOZ._dualPane then
    if self:_ltHeld(playerNum) then
      if not TLOZ._itemDualSenseActive then
        dualSenseStart("item_radial")
        TLOZ._itemDualSenseActive = true
      end
      TLOZ._itemRadialHoldMs = TLOZ._itemRadialHoldMs + self:_tickDelta()
      if not TLOZ._itemRadialOpened and TLOZ._itemRadialHoldMs >= 250 then
        local item = TLOZ._dualPane.getSelectedItem and TLOZ._dualPane:getSelectedItem()
        if item then
          TLOZ.RadialSatellites.openItem(item, TLOZ._dualPane.playerNum)
        end
        TLOZ._itemRadialOpened = true
      end
    else
      if TLOZ._itemDualSenseActive then
        dualSenseEnd("item_radial")
        TLOZ._itemDualSenseActive = false
      end
      TLOZ._itemRadialHoldMs = 0
      TLOZ._itemRadialOpened = false
    end
    return
  end

  if focus ~= "world" then
    TLOZ._worldRadialHoldMs = 0
    TLOZ._worldRadialOpened = false
    TLOZ._equipRadialHoldMs = 0
    TLOZ._equipRadialOpened = false
    return
  end

  local player = getSpecificPlayer(playerNum)
  if not player then return end

  if self:_confirmHeld(playerNum) then
    TLOZ._worldRadialHoldMs = TLOZ._worldRadialHoldMs + self:_tickDelta()
    if not TLOZ._worldRadialOpened and TLOZ._worldRadialHoldMs >= 250 then
      -- Perto/dentro de veículo: atalho Veículo; senão radial de mundo (porta/etc.)
      if TLOZ.RadialSatellites.canUseVehicleShortcut
          and TLOZ.RadialSatellites.canUseVehicleShortcut(player) then
        TLOZ.RadialSatellites.openVehicle(player)
      else
        TLOZ.RadialSatellites.openWorld(player:getCurrentSquare(), player)
      end
      TLOZ._worldRadialOpened = true
    end
  else
    TLOZ._worldRadialHoldMs = 0
    TLOZ._worldRadialOpened = false
  end

  if self:_rtHeld(playerNum) then
    TLOZ._equipRadialHoldMs = TLOZ._equipRadialHoldMs + self:_tickDelta()
    if not TLOZ._equipRadialOpened and TLOZ._equipRadialHoldMs >= 250 then
      TLOZ.RadialSatellites.openEquipQuick(player)
      TLOZ._equipRadialOpened = true
    end
  else
    TLOZ._equipRadialHoldMs = 0
    TLOZ._equipRadialOpened = false
  end
end

function TLOZ.GamepadShell:tickHub(playerNum)
  if TLOZ._activeShell ~= "gamepad" then return end
  if not TLOZ._router or TLOZ._router:getMode() ~= TLOZ.InputMode.GAMEPAD then return end
  playerNum = playerNum or 0

  if TLOZ._radialHub and TLOZ._focus and TLOZ._focus:peek() == "radial_hub" then
    local angle = self:_stickAngle(playerNum)
    if angle then TLOZ._radialHub:setStickDirection(angle) end
    if not self:_lbHeld(playerNum) then
      if TLOZ._hubDualSenseActive then
        dualSenseEnd("hub")
        TLOZ._hubDualSenseActive = false
      end
      TLOZ._radialHub:close()
      TLOZ._radialHub = nil
      TLOZ._hubOpenedThisPress = false
      TLOZ._hubHoldMs = 0
    end
    return
  end

  if not TLOZ._focus or TLOZ._focus:peek() ~= "world" then
    if TLOZ._hubDualSenseActive then
      dualSenseEnd("hub")
      TLOZ._hubDualSenseActive = false
    end
    TLOZ._hubHoldMs = 0
    TLOZ._hubOpenedThisPress = false
    return
  end

  if self:_lbHeld(playerNum) then
    if not TLOZ._hubDualSenseActive then
      dualSenseStart("hub")
      TLOZ._hubDualSenseActive = true
    end
    local dt = 16
    if UIManager and UIManager.getMillisDelta then
      dt = UIManager.getMillisDelta() or dt
    end
    TLOZ._hubHoldMs = TLOZ._hubHoldMs + dt
    if not TLOZ._hubOpenedThisPress and TLOZ._hubHoldMs >= 250 then
      TLOZ._radialHub = TLOZ.RadialHub:new()
      TLOZ._radialHub.playerNum = playerNum
      TLOZ._radialHub:open()
      TLOZ._hubOpenedThisPress = true
    end
  else
    if TLOZ._hubDualSenseActive then
      dualSenseEnd("hub")
      TLOZ._hubDualSenseActive = false
    end
    TLOZ._hubHoldMs = 0
    TLOZ._hubOpenedThisPress = false
  end
end

function TLOZ.GamepadShell:deactivate()
  if TLOZ._legend then
    TLOZ._legend:removeFromUIManager()
    TLOZ._legend = nil
  end
  if TLOZ._dualPane then
    TLOZ._dualPane:close()
    TLOZ._dualPane = nil
  end
  if TLOZ._hubDualSenseActive then
    dualSenseEnd("hub")
    TLOZ._hubDualSenseActive = false
  end
  if TLOZ._itemDualSenseActive then
    dualSenseEnd("item_radial")
    TLOZ._itemDualSenseActive = false
  end
  if TLOZ._radialHub then
    TLOZ._radialHub:close()
    TLOZ._radialHub = nil
  end
  if TLOZ._satPanel then
    TLOZ._satPanel:close()
    TLOZ._satPanel = nil
  end
  if TLOZ._focus then TLOZ._focus:clear() end
  TLOZ._activeShell = "kbm"
end
