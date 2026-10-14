-- media/lua/client/TLOZ/bootstrap.lua
require "TLOZ/Strings_PT"
require "TLOZ/InputMode"
require "TLOZ/InputRouter"
require "TLOZ/FocusStack"
require "TLOZ/CategoryFilter"
require "TLOZ/RadialSlice"
require "TLOZ/JoypadBindMap"
require "TLOZ/ButtonLegendModel"
require "TLOZ/DualSensePolicy"
require "TLOZ/ButtonLegend"
require "TLOZ/InventoryListPane"
require "TLOZ/DualPaneInventory"
require "TLOZ/RadialHub"
require "TLOZ/RadialSatellites"
require "TLOZ/DualSenseHooks"
require "TLOZ/UIShell"

local router = TLOZ.InputRouter.new()
TLOZ.UIShell.start(router)

local function onJoypadActivate(joypadData)
  local name = ""
  if joypadData and joypadData.controller and joypadData.controller.getName then
    name = joypadData.controller:getName() or ""
  end
  TLOZ._glyphFamily = TLOZ.JoypadBindMap.detectFamily(name)
  router:onDecisiveInput("gamepad")
end

local function onKeyPressed(key)
  -- qualquer tecla decisiva volta a KBM (exceto se quisermos whitelist)
  if TLOZ._router and TLOZ._router:getMode() == TLOZ.InputMode.GAMEPAD then
    router:onDecisiveInput("keyboard")
  end
end

local function openDualPane(playerNum)
  if not TLOZ._router or TLOZ._router:getMode() ~= TLOZ.InputMode.GAMEPAD then return end
  if TLOZ._dualPane then
    TLOZ._dualPane:close()
    TLOZ._dualPane = nil
    return
  end
  TLOZ._dualPane = TLOZ.DualPaneInventory:new(playerNum or 0)
  TLOZ._dualPane:open()
end

local function closeDualPane(playerNum)
  if TLOZ._dualPane and (playerNum == nil or TLOZ._dualPane.playerNum == playerNum) then
    TLOZ._dualPane:close()
    TLOZ._dualPane = nil
  end
end

TLOZ.openDualPane = openDualPane
TLOZ.closeDualPane = closeDualPane

local function joyButton(name, fallback)
  if Joypad and Joypad[name] then return Joypad[name] end
  return fallback
end

local function onJoypadButtonPressed(button, joypadData)
  if not TLOZ._router or TLOZ._router:getMode() ~= TLOZ.InputMode.GAMEPAD then return end
  local playerNum = 0
  if joypadData and joypadData.player then
    playerNum = joypadData.player
  end
  if TLOZ._focus and TLOZ._focus:peek() == "radial_hub" and TLOZ._radialHub then
    if TLOZ._radialHub.onJoypadDown and TLOZ._radialHub:onJoypadDown(button) then
      if TLOZ._focus:peek() ~= "radial_hub" then
        TLOZ._radialHub = nil
      end
      return
    end
  end
  if TLOZ._focus and TLOZ._focus:peek() == "radial_sat" and TLOZ._satPanel then
    if TLOZ._satPanel.onJoypadDown and TLOZ._satPanel:onJoypadDown(button) then
      return
    end
  end
  local Y = joyButton("YButton", 3)
  if button == Y and (not TLOZ._focus or TLOZ._focus:peek() == "world") then
    openDualPane(playerNum)
  end
end

if Events.OnJoypadButtonPressed then
  Events.OnJoypadButtonPressed.Add(onJoypadButtonPressed)
end

local function onTickHub()
  if TLOZ.GamepadShell and TLOZ.GamepadShell.tickHub then
    TLOZ.GamepadShell:tickHub(0)
  end
  if TLOZ.GamepadShell and TLOZ.GamepadShell.tickSatellites then
    TLOZ.GamepadShell:tickSatellites(0)
  end
end

if Events and Events.OnTick then
  Events.OnTick.Add(onTickHub)
end

Events.OnJoypadActivate.Add(onJoypadActivate)
Events.OnKeyStartPressed.Add(onKeyPressed)
print("[TLOZ] dual-UI router armed")
