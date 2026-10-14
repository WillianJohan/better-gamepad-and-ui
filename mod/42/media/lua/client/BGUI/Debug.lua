-- media/lua/client/BGUI/Debug.lua
-- Hot-reload pra iterar no console de debug sem reiniciar o jogo.
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
    removeEvent("OnKeyStartPressed", h.keyPressed)
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

local function wipeBguiTable()
  local keys = {}
  for k, _ in pairs(BGUI) do
    keys[#keys + 1] = k
  end
  for i = 1, #keys do
    BGUI[keys[i]] = nil
  end
end

--- Fecha UI, desarma events, limpa módulos BGUI e reexecuta o bootstrap.
function BGUI.reload()
  local ok, err = pcall(function()
    BGUI.closeOpenUi()
    BGUI.disarmEvents()
    BGUI.clearLoadedModules()
    wipeBguiTable()
    require "BGUI/bootstrap"
  end)
  if ok then
    print("[BGUI] reload ok")
  else
    print("[BGUI] reload failed: " .. tostring(err))
  end
  return ok
end
