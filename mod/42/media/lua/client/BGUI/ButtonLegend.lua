-- media/lua/client/BGUI/ButtonLegend.lua
require "BGUI/ButtonLegendModel"
BGUI = BGUI or {}
BGUI.ButtonLegend = ISUIElement:derive("BGUI.ButtonLegend")

function BGUI.ButtonLegend:new(x, y, w, h)
  local o = ISUIElement:new(x, y, w, h)
  setmetatable(o, self)
  self.__index = self
  o.context = "world"
  o.family = "xbox"
  return o
end

function BGUI.ButtonLegend:setContext(context, family)
  self.context = context
  self.family = family or self.family
end

function BGUI.ButtonLegend:render()
  local entries = BGUI.ButtonLegendModel.buildEntries(self.context, self.family)
  local x = 8
  for i = 1, #entries do
    local e = entries[i]
    self:drawText(e.glyph .. " " .. e.label, x, 4, 1, 1, 1, 1, UIFont.Small)
    x = x + 120
  end
end
