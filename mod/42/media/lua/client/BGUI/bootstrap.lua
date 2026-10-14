-- media/lua/client/BGUI/bootstrap.lua
require "BGUI/Strings_PT"
require "BGUI/InputMode"
require "BGUI/InputRouter"
require "BGUI/FocusStack"
require "BGUI/CategoryFilter"
require "BGUI/RadialSlice"
require "BGUI/JoypadBindMap"
require "BGUI/ButtonLegendModel"
require "BGUI/DualSensePolicy"
require "BGUI/ButtonLegend"
require "BGUI/InventoryListPane"
require "BGUI/DualPaneInventory"
require "BGUI/RadialHub"
require "BGUI/RadialSatellites"
require "BGUI/DualSenseHooks"
require "BGUI/UIShell"

local router = BGUI.InputRouter.new()
BGUI.UIShell.start(router)

local function onJoypadActivate(joypadData)
  local name = ""
  if joypadData and joypadData.controller and joypadData.controller.getName then
    name = joypadData.controller:getName() or ""
  end
  BGUI._glyphFamily = BGUI.JoypadBindMap.detectFamily(name)
  router:onDecisiveInput("gamepad")
end

local function onKeyPressed(key)
  -- qualquer tecla decisiva volta a KBM (exceto se quisermos whitelist)
  if BGUI._router and BGUI._router:getMode() == BGUI.InputMode.GAMEPAD then
    router:onDecisiveInput("keyboard")
  end
end

local function openDualPane(playerNum)
  if not BGUI._router or BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then return end
  if BGUI._dualPane then
    BGUI._dualPane:close()
    BGUI._dualPane = nil
    return
  end
  BGUI._dualPane = BGUI.DualPaneInventory:new(playerNum or 0)
  BGUI._dualPane:open()
end

local function closeDualPane(playerNum)
  if BGUI._dualPane and (playerNum == nil or BGUI._dualPane.playerNum == playerNum) then
    BGUI._dualPane:close()
    BGUI._dualPane = nil
  end
end

BGUI.openDualPane = openDualPane
BGUI.closeDualPane = closeDualPane

local function joyButton(name, fallback)
  if Joypad and Joypad[name] then return Joypad[name] end
  return fallback
end

local function onJoypadButtonPressed(button, joypadData)
  if not BGUI._router or BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then return end
  local playerNum = 0
  if joypadData and joypadData.player then
    playerNum = joypadData.player
  end
  if BGUI._focus and BGUI._focus:peek() == "radial_hub" and BGUI._radialHub then
    if BGUI._radialHub.onJoypadDown and BGUI._radialHub:onJoypadDown(button) then
      if BGUI._focus:peek() ~= "radial_hub" then
        BGUI._radialHub = nil
      end
      return
    end
  end
  if BGUI._focus and BGUI._focus:peek() == "radial_sat" and BGUI._satPanel then
    if BGUI._satPanel.onJoypadDown and BGUI._satPanel:onJoypadDown(button) then
      return
    end
  end
  local Y = joyButton("YButton", 3)
  if button == Y and (not BGUI._focus or BGUI._focus:peek() == "world") then
    openDualPane(playerNum)
  end
end

if Events.OnJoypadButtonPressed then
  Events.OnJoypadButtonPressed.Add(onJoypadButtonPressed)
end

local function onTickHub()
  if BGUI.GamepadShell and BGUI.GamepadShell.tickHub then
    BGUI.GamepadShell:tickHub(0)
  end
  if BGUI.GamepadShell and BGUI.GamepadShell.tickSatellites then
    BGUI.GamepadShell:tickSatellites(0)
  end
end

if Events and Events.OnTick then
  Events.OnTick.Add(onTickHub)
end

Events.OnJoypadActivate.Add(onJoypadActivate)
Events.OnKeyStartPressed.Add(onKeyPressed)
print("[BGUI] dual-UI router armed")
