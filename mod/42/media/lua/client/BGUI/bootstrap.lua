-- media/lua/client/BGUI/bootstrap.lua
-- Debug PRIMEIRO: mesmo se o resto falhar, BGUI.reload / BGUI.status existem.
BGUI = BGUI or {}
require "BGUI/Debug"

local bootOk, bootErr = pcall(function()
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

  local function joyButton(name, fallback)
    if Joypad and Joypad[name] then return Joypad[name] end
    return fallback
  end

  --- True se há joypad jogável (players[] ou joypad com player atribuído).
  function BGUI.isJoypadAssigned()
    if not JoypadState then return false end
    if JoypadState.players then
      for i = 1, 4 do
        if JoypadState.players[i] then return true end
      end
    end
    -- player 0 é válido — usar ~= nil, não truthiness
    if JoypadState.joypads then
      for i = 1, 4 do
        local jd = JoypadState.joypads[i]
        if jd and jd.player ~= nil and jd.controller and jd.controller.connected then
          return true
        end
      end
    end
    if JoypadState.controllers then
      for id = 0, 15 do
        local c = JoypadState.controllers[id]
        if c and c.connected and c.joypad and c.joypad.player ~= nil then
          return true
        end
      end
    end
    return false
  end

  local function controllerNameFromJoypad(joypadId)
    if not JoypadState then return "" end
    local j = nil
    -- OnJoypadActivate passa id do controller (0..15), não índice de player.
    if type(joypadId) == "number" and JoypadState.controllers then
      local c = JoypadState.controllers[joypadId]
      if c and c.getName then
        return c:getName() or ""
      end
      if c and c.joypad then j = c.joypad end
    end
    if not j and JoypadState.players then
      for i = 1, 4 do
        if JoypadState.players[i] then
          j = JoypadState.players[i]
          break
        end
      end
    end
    if j and j.controller and j.controller.getName then
      return j.controller:getName() or ""
    end
    if j and j.getController and j:getController() and j:getController().getName then
      return j:getController():getName() or ""
    end
    return ""
  end

  --- Força modo gamepad + GamepadShell (idempotente se já estiver nele).
  function BGUI.enterGamepadMode(joypadId)
    local prev = BGUI._router and BGUI._router:getMode() or nil
    local name = controllerNameFromJoypad(joypadId)
    if BGUI.JoypadBindMap and BGUI.JoypadBindMap.detectFamily then
      BGUI._glyphFamily = BGUI.JoypadBindMap.detectFamily(name)
    end
    if BGUI._router then
      BGUI._router:onDecisiveInput("gamepad")
    end
    if prev ~= BGUI.InputMode.GAMEPAD then
      print("[BGUI] enter gamepad shell=" .. tostring(BGUI._activeShell)
        .. " joypad=" .. tostring(BGUI.isJoypadAssigned())
        .. " glyph=" .. tostring(BGUI._glyphFamily))
    end
  end

  --- Se o pad já estiver atribuído, entra no shell gamepad agora.
  function BGUI.syncInputModeFromHardware()
    if BGUI.isJoypadAssigned() then
      BGUI.enterGamepadMode()
      return true
    end
    return false
  end

  local function onJoypadActivate(joypadId)
    -- B42: OnJoypadActivate(joypadId: integer = controller id).
    BGUI.enterGamepadMode(joypadId)
  end

  local function onKeyPressed(key)
    -- Com pad atribuído, não voltar pra KBM por tecla (console de debug dispara isso).
    if BGUI.isJoypadAssigned and BGUI.isJoypadAssigned() then return end
    if BGUI._router and BGUI._router:getMode() == BGUI.InputMode.GAMEPAD then
      router:onDecisiveInput("keyboard")
    end
  end

  local function openDualPane(playerNum)
    BGUI.enterGamepadMode()
    if not BGUI._router or BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then return end
    if BGUI._dualPane then
      BGUI._dualPane:close()
      BGUI._dualPane = nil
      return
    end
    if BGUI.GamepadShell and BGUI.GamepadShell.hideVanillaInventory then
      BGUI.GamepadShell:hideVanillaInventory(playerNum or 0)
    end
    BGUI._dualPane = BGUI.DualPaneInventory:new(playerNum or 0)
    BGUI._dualPane:open()
    print("[BGUI] dual-pane open player=" .. tostring(playerNum or 0))
  end

  local function closeDualPane(playerNum)
    if BGUI._dualPane and (playerNum == nil or BGUI._dualPane.playerNum == playerNum) then
      BGUI._dualPane:close()
      BGUI._dualPane = nil
    end
  end

  BGUI.openDualPane = openDualPane
  BGUI.closeDualPane = closeDualPane

  --- Handler opcional: B42.21 não documenta OnJoypadButtonPressed; mantemos se existir.
  local function onJoypadButtonPressed(button, joypadData)
    BGUI.enterGamepadMode()
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

  local function dispatchJoypadDown(button, playerNum)
    playerNum = playerNum or 0
    if BGUI._focus and BGUI._focus:peek() == "dualpane" and BGUI._dualPane then
      if BGUI._dualPane.onJoypadDown and BGUI._dualPane:onJoypadDown(button) then
        return true
      end
    end
    if BGUI._focus and BGUI._focus:peek() == "radial_hub" and BGUI._radialHub then
      if BGUI._radialHub.onJoypadDown and BGUI._radialHub:onJoypadDown(button) then
        if BGUI._focus:peek() ~= "radial_hub" then
          BGUI._radialHub = nil
        end
        return true
      end
    end
    if BGUI._focus and BGUI._focus:peek() == "radial_sat" and BGUI._satPanel then
      if BGUI._satPanel.onJoypadDown and BGUI._satPanel:onJoypadDown(button) then
        return true
      end
    end
    return false
  end

  --- Poll de botões: B42 não tem OnJoypadButtonPressed confiável.
  local function tickJoypadEdges(playerNum)
    playerNum = playerNum or 0
    if not BGUI.GamepadShell then return end

    local anyHeld = BGUI.GamepadShell:_lbHeld(playerNum)
        or BGUI.GamepadShell:_ltHeld(playerNum)
        or BGUI.GamepadShell:_rtHeld(playerNum)
        or BGUI.GamepadShell:_confirmHeld(playerNum)
        or BGUI.GamepadShell:_yHeld(playerNum)
    if anyHeld then
      BGUI.enterGamepadMode()
    end

    if not BGUI._router or BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then
      BGUI._yWasHeld = false
      BGUI._bWasHeld = false
      return
    end

    local yHeld = BGUI.GamepadShell:_yHeld(playerNum)
    if yHeld and not BGUI._yWasHeld then
      local focus = BGUI._focus and BGUI._focus:peek()
      if focus == "world" or focus == nil then
        openDualPane(playerNum)
      elseif focus == "dualpane" then
        dispatchJoypadDown(joyButton("YButton", 3), playerNum)
      end
    end
    BGUI._yWasHeld = yHeld

    local bHeld = BGUI.GamepadShell:_buttonHeld(playerNum, "_testBHeld", "BButton", 1, "isBPressed")
    if bHeld and not BGUI._bWasHeld then
      dispatchJoypadDown(joyButton("BButton", 1), playerNum)
    end
    BGUI._bWasHeld = bHeld

    local aHeld = BGUI.GamepadShell:_confirmHeld(playerNum)
    if aHeld and not BGUI._aWasHeld then
      local focus = BGUI._focus and BGUI._focus:peek()
      if focus == "dualpane" or focus == "radial_hub" or focus == "radial_sat" then
        dispatchJoypadDown(joyButton("AButton", 0), playerNum)
      end
    end
    BGUI._aWasHeld = aHeld

    local xHeld = BGUI.GamepadShell:_buttonHeld(playerNum, "_testXHeld", "XButton", 2, "isXPressed")
    if xHeld and not BGUI._xWasHeld then
      dispatchJoypadDown(joyButton("XButton", 2), playerNum)
    end
    BGUI._xWasHeld = xHeld
  end

  local function onTickHub()
    if BGUI.isJoypadAssigned and BGUI.isJoypadAssigned() then
      if BGUI._router and BGUI._router:getMode() ~= BGUI.InputMode.GAMEPAD then
        BGUI.enterGamepadMode()
      end
    end
    tickJoypadEdges(0)
    if BGUI.GamepadShell and BGUI.GamepadShell.tickHub then
      BGUI.GamepadShell:tickHub(0)
    end
    if BGUI.GamepadShell and BGUI.GamepadShell.tickSatellites then
      BGUI.GamepadShell:tickSatellites(0)
    end
  end

  local function onGameStart()
    BGUI.syncInputModeFromHardware()
  end

  local function onCreatePlayer(_playerIndex, _player)
    BGUI.syncInputModeFromHardware()
  end

  BGUI._handlers = {
    joypadButton = onJoypadButtonPressed,
    tickHub = onTickHub,
    joypadActivate = onJoypadActivate,
    joypadActivateUi = onJoypadActivate,
    joypadReactivate = onJoypadActivate,
    gamepadConnect = onJoypadActivate,
    gameStart = onGameStart,
    createPlayer = onCreatePlayer,
    keyPressed = onKeyPressed,
    keyPressedAlt = onKeyPressed,
  }

  local function addEv(name, fn)
    if Events and Events[name] and Events[name].Add then
      Events[name].Add(fn)
    end
  end

  addEv("OnJoypadButtonPressed", onJoypadButtonPressed)
  addEv("OnTick", onTickHub)
  addEv("OnJoypadActivate", onJoypadActivate)
  addEv("OnJoypadActivateUI", onJoypadActivate)
  addEv("OnJoypadReactivate", onJoypadActivate)
  addEv("OnGamepadConnect", onJoypadActivate)
  addEv("OnGameStart", onGameStart)
  addEv("OnCreatePlayer", onCreatePlayer)
  addEv("OnKeyStartPressed", onKeyPressed)
  addEv("OnKeyPressed", onKeyPressed)

  BGUI._yWasHeld = false
  BGUI._bWasHeld = false
  BGUI._aWasHeld = false
  BGUI._xWasHeld = false

  -- Cold start / reload: se o pad já está ativo, não esperar OnJoypadActivate de novo.
  BGUI.syncInputModeFromHardware()

  -- B42: Y do pad chama ISButtonPrompt.cmdShowInventory — redireciona pro dual-pane.
  -- Marcador na classe (não em BGUI) pra não re-embrulhar no hot-reload.
  if ISButtonPrompt and not ISButtonPrompt._bguiInvHooked then
    ISButtonPrompt._bguiInvHooked = true
    local origInv = ISButtonPrompt.cmdShowInventory
    local origLoot = ISButtonPrompt.cmdShowLoot
    function ISButtonPrompt:cmdShowInventory()
      if BGUI and BGUI.openDualPane then
        BGUI.openDualPane(self.player or 0)
        return
      end
      if origInv then return origInv(self) end
    end
    function ISButtonPrompt:cmdShowLoot()
      if BGUI and BGUI.openDualPane then
        BGUI.openDualPane(self.player or 0)
        return
      end
      if origLoot then return origLoot(self) end
    end
  end

  if not BGUI._router then
    error("UIShell.start did not set BGUI._router")
  end

  print("[BGUI] dual-UI router armed mode=" .. tostring(router:getMode())
    .. " shell=" .. tostring(BGUI._activeShell)
    .. " joypad=" .. tostring(BGUI.isJoypadAssigned()))
end)

if bootOk then
  BGUI._bootOk = true
else
  BGUI._bootOk = false
  print("[BGUI] bootstrap failed: " .. tostring(bootErr))
  print("[BGUI] helpers still available: BGUI.reload() / BGUI.status() / BGUI_rebootstrap()")
end

-- Reafirmar helpers se Debug carregou; nunca assert (Kahlua/load do jogo).
if type(BGUI.reload) ~= "function" or type(BGUI.status) ~= "function" then
  print("[BGUI] CRITICAL: reload/status missing after bootstrap — run BGUI_rebootstrap()")
end