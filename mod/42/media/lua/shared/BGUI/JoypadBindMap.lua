-- media/lua/shared/BGUI/JoypadBindMap.lua
BGUI = BGUI or {}
BGUI.JoypadBindMap = {
  ps = {
    confirm = "✕",
    cancel = "○",
    openInv = "△",
    swapSide = "□",
    tabPrev = "L1",
    tabNext = "R1",
    itemRadial = "L2",
    hub = "L1",
  },
  xbox = {
    confirm = "A",
    cancel = "B",
    openInv = "Y",
    swapSide = "X",
    tabPrev = "LB",
    tabNext = "RB",
    itemRadial = "LT",
    hub = "LB",
  },
}

function BGUI.JoypadBindMap.glyph(family, action)
  local t = BGUI.JoypadBindMap[family] or BGUI.JoypadBindMap.xbox
  return t[action] or "?"
end

function BGUI.JoypadBindMap.detectFamily(controllerName)
  local n = string.lower(controllerName or "")
  if string.find(n, "dualsense", 1, true) or string.find(n, "wireless controller", 1, true)
      or string.find(n, "playstation", 1, true) then
    return "ps"
  end
  return "xbox"
end
