BGUI = BGUI or {}
BGUI.FocusStack = BGUI.FocusStack or {}

local Stack = {}
Stack.__index = Stack

function BGUI.FocusStack.new()
  return setmetatable({ _items = {} }, Stack)
end

function Stack:push(id)
  self._items[#self._items + 1] = id
end

function Stack:pop()
  local n = #self._items
  if n == 0 then return nil end
  local v = self._items[n]
  self._items[n] = nil
  return v
end

function Stack:peek()
  return self._items[#self._items]
end

function Stack:clear()
  self._items = {}
end

function Stack:depth()
  return #self._items
end
