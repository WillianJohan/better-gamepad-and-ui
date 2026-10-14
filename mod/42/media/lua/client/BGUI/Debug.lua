-- media/lua/client/BGUI/Debug.lua
-- Hot-reload e status no console de debug (sem reiniciar o jogo).
-- Este ficheiro DEVE ser o primeiro require do bootstrap — define sempre
-- BGUI.reload / BGUI.status mesmo se o resto do init falhar.
BGUI = BGUI or {}

local function safeCall(fn)
  if not fn then return end
  local ok, err = pcall(fn)
  if not ok then
    print("[BGUI] reload warn: " .. tostring(err))
  end
end

--- Fecha painéis BGUI abertos (dual-pane, radiais, legend). Idempotente.
function BGUI.closeOpenUi()
  if BGUI.GamepadShell and BGUI.GamepadShell.deactivate then
    safeCall(function()
      BGUI.GamepadShell:deactivate()
    end)
  end
  if BGUI._dualPane then
    safeCall(function()
      if BGUI._dualPane.close then BGUI._dualPane:close() end
    end)
    BGUI._dualPane = nil
  end
  if BGUI._radialHub then
    safeCall(function()
      if BGUI._radialHub.close then BGUI._radialHub:close() end
    end)
    BGUI._radialHub = nil
  end
  if BGUI._satPanel then
    safeCall(function()
      if BGUI._satPanel.close then BGUI._satPanel:close() end
    end)
    BGUI._satPanel = nil
  end
  if BGUI._legend then
    safeCall(function()
      if BGUI._legend.removeFromUIManager then
        BGUI._legend:removeFromUIManager()
      end
    end)
    BGUI._legend = nil
  end
end

local function removeEvent(evName, fn)
  if not fn then return end
  if not Events or not Events[evName] or not Events[evName].Remove then return end
  safeCall(function()
    Events[evName].Remove(fn)
  end)
end

--- Remove handlers do bootstrap / shell. Seguro se já estiver limpo.
function BGUI.disarmEvents()
  local h = BGUI._handlers
  if h then
    removeEvent("OnJoypadButtonPressed", h.joypadButton)
    removeEvent("OnTick", h.tickHub)
    removeEvent("OnJoypadActivate", h.joypadActivate)
    removeEvent("OnJoypadActivateUI", h.joypadActivateUi)
    removeEvent("OnJoypadReactivate", h.joypadReactivate)
    removeEvent("OnGamepadConnect", h.gamepadConnect)
    removeEvent("OnGameStart", h.gameStart)
    removeEvent("OnCreatePlayer", h.createPlayer)
    removeEvent("OnKeyStartPressed", h.keyPressed)
    removeEvent("OnKeyPressed", h.keyPressedAlt)
  end
  removeEvent("OnTick", BGUI._vanillaInvGuard)
  BGUI._handlers = nil
  BGUI._vanillaInvGuard = nil
end

local function isBguiPackageKey(k)
  if type(k) ~= "string" then return false end
  if string.sub(k, 1, 5) == "BGUI/" then return true end
  if string.sub(k, 1, 5) == "BGUI." then return true end
  return false
end

--- Nil em package.loaded["BGUI/…"] pra o próximo require reler o disco.
function BGUI.clearLoadedModules()
  if not package or not package.loaded then return end
  local keys = {}
  for k, _ in pairs(package.loaded) do
    if isBguiPackageKey(k) then
      keys[#keys + 1] = k
    end
  end
  for i = 1, #keys do
    package.loaded[keys[i]] = nil
  end
end

local function wipeBguiTable(keep)
  local keys = {}
  for k, _ in pairs(BGUI) do
    if not keep or keep[k] == nil then
      keys[#keys + 1] = k
    end
  end
  for i = 1, #keys do
    BGUI[keys[i]] = nil
  end
end

local function yn(v)
  if v then return "yes" else return "no" end
end

--- Imprime estado do mod no console. Johan: cole a saída se algo falhar.
function BGUI.status()
  local mode = "nil"
  if BGUI._router and BGUI._router.getMode then
    mode = tostring(BGUI._router:getMode())
  end
  local focus = "nil"
  if BGUI._focus and BGUI._focus.peek then
    focus = tostring(BGUI._focus:peek())
  end
  local joy = "no"
  if BGUI.isJoypadAssigned and BGUI.isJoypadAssigned() then
    joy = "yes"
  end
  print("[BGUI.status] mode=" .. mode
    .. " activeShell=" .. tostring(BGUI._activeShell)
    .. " focus=" .. focus
    .. " joypadAssigned=" .. joy
    .. " dualPane=" .. yn(BGUI._dualPane ~= nil)
    .. " radialHub=" .. yn(BGUI._radialHub ~= nil)
    .. " satPanel=" .. yn(BGUI._satPanel ~= nil)
    .. " legend=" .. yn(BGUI._legend ~= nil)
    .. " bootOk=" .. yn(BGUI._bootOk)
    .. " glyph=" .. tostring(BGUI._glyphFamily)
    .. " hasReload=" .. yn(type(BGUI.reload) == "function")
    .. " hasRouter=" .. yn(BGUI._router ~= nil))
  return {
    mode = mode,
    activeShell = BGUI._activeShell,
    focus = focus,
    joypadAssigned = joy == "yes",
    dualPane = BGUI._dualPane ~= nil,
    radialHub = BGUI._radialHub ~= nil,
    satPanel = BGUI._satPanel ~= nil,
    legend = BGUI._legend ~= nil,
    bootOk = BGUI._bootOk == true,
  }
end

--- Recuperação quando BGUI.reload sumiu (tabela half-dead). Global, não vive só em BGUI.
function BGUI_rebootstrap()
  BGUI = BGUI or {}
  if BGUI.disarmEvents then
    safeCall(BGUI.disarmEvents)
  end
  if BGUI.closeOpenUi then
    safeCall(BGUI.closeOpenUi)
  end
  if BGUI.clearLoadedModules then
    BGUI.clearLoadedModules()
  elseif package and package.loaded then
    local keys = {}
    for k, _ in pairs(package.loaded) do
      if isBguiPackageKey(k) then keys[#keys + 1] = k end
    end
    for i = 1, #keys do package.loaded[keys[i]] = nil end
  end
  -- Garante re-require mesmo se clearLoadedModules não existia.
  if package and package.loaded then
    package.loaded["BGUI/Debug"] = nil
    package.loaded["BGUI/bootstrap"] = nil
  end
  local ok, err = pcall(function()
    require "BGUI/bootstrap"
  end)
  if ok and BGUI._router then
    print("[BGUI] rebootstrap ok")
    if BGUI.status then BGUI.status() end
    return true
  end
  print("[BGUI] rebootstrap failed: " .. tostring(err or "no router"))
  -- Debug pode ter sido carregado a meio — tenta pelo menos repor helpers.
  pcall(function()
    package.loaded["BGUI/Debug"] = nil
    require "BGUI/Debug"
  end)
  return false
end

--- Fecha UI, desarma events, limpa módulos BGUI e reexecuta o bootstrap.
--- Se o bootstrap falhar, preserva reload/status (não deixa a tabela morta).
function BGUI.reload()
  local keepReload = BGUI.reload
  local keepStatus = BGUI.status
  local keepClose = BGUI.closeOpenUi
  local keepDisarm = BGUI.disarmEvents
  local keepClear = BGUI.clearLoadedModules

  local ok, err = pcall(function()
    if BGUI.closeOpenUi then BGUI.closeOpenUi() end
    if BGUI.disarmEvents then BGUI.disarmEvents() end
    if BGUI.clearLoadedModules then BGUI.clearLoadedModules() end
    -- Mantém helpers de debug durante o require; bootstrap reatribui o resto.
    wipeBguiTable({
      reload = true,
      status = true,
      closeOpenUi = true,
      disarmEvents = true,
      clearLoadedModules = true,
    })
    BGUI.reload = keepReload
    BGUI.status = keepStatus
    BGUI.closeOpenUi = keepClose
    BGUI.disarmEvents = keepDisarm
    BGUI.clearLoadedModules = keepClear
    require "BGUI/bootstrap"
    if type(BGUI.reload) ~= "function" then
      error("bootstrap did not redefine BGUI.reload")
    end
    if type(BGUI.status) ~= "function" then
      error("bootstrap did not redefine BGUI.status")
    end
    if not BGUI._router then
      error("bootstrap did not create BGUI._router")
    end
    if not BGUI._bootOk then
      error("bootstrap did not set BGUI._bootOk")
    end
  end)

  if ok then
    print("[BGUI] reload ok")
    if BGUI.status then BGUI.status() end
  else
    BGUI = BGUI or {}
    BGUI.reload = keepReload
    BGUI.status = keepStatus
    BGUI.closeOpenUi = keepClose
    BGUI.disarmEvents = keepDisarm
    BGUI.clearLoadedModules = keepClear
    BGUI._bootOk = false
    print("[BGUI] reload failed: " .. tostring(err))
    print("[BGUI] helpers preserved — or run: BGUI_rebootstrap()")
  end
  return ok
end
