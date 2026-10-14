BGUI = BGUI or {}
require "BGUI/InputMode"
BGUI.InputRouter = BGUI.InputRouter or {}

local Router = {}
Router.__index = Router

function BGUI.InputRouter.new()
  return setmetatable({
    _mode = BGUI.InputMode.KBM,
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
  if mode == BGUI.InputMode.GAMEPAD then
    fire(self._enter)
  elseif prev == BGUI.InputMode.GAMEPAD then
    fire(self._exit)
  end
end

function Router:onDecisiveInput(kind)
  if kind == "gamepad" then
    self:forceMode(BGUI.InputMode.GAMEPAD)
  elseif kind == "keyboard" or kind == "mouse" then
    self:forceMode(BGUI.InputMode.KBM)
  end
end
