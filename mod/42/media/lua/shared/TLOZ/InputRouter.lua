TLOZ = TLOZ or {}
require "TLOZ/InputMode"
TLOZ.InputRouter = TLOZ.InputRouter or {}

local Router = {}
Router.__index = Router

function TLOZ.InputRouter.new()
  return setmetatable({
    _mode = TLOZ.InputMode.KBM,
    _enter = {},
    _exit = {},
  }, Router)
end

function Router:getMode()
  return self._mode
end

function Router:onEnterGamepad(fn)
  self._enter[#self._enter + 1] = fn
end

function Router:onExitGamepad(fn)
  self._exit[#self._exit + 1] = fn
end

local function fire(list)
  for i = 1, #list do list[i]() end
end

function Router:forceMode(mode)
  if mode == self._mode then return end
  local prev = self._mode
  self._mode = mode
  if mode == TLOZ.InputMode.GAMEPAD then
    fire(self._enter)
  elseif prev == TLOZ.InputMode.GAMEPAD then
    fire(self._exit)
  end
end

function Router:onDecisiveInput(kind)
  if kind == "gamepad" then
    self:forceMode(TLOZ.InputMode.GAMEPAD)
  elseif kind == "keyboard" or kind == "mouse" then
    self:forceMode(TLOZ.InputMode.KBM)
  end
end
