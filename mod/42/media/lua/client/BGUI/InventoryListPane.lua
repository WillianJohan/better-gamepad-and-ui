-- media/lua/client/BGUI/InventoryListPane.lua
require "BGUI/Strings_PT"
require "BGUI/CategoryFilter"

BGUI = BGUI or {}
BGUI.InventoryListPane = ISPanel:derive("BGUI.InventoryListPane")

function BGUI.InventoryListPane:new(x, y, w, h, title)
  local o = ISPanel:new(x, y, w, h)
  setmetatable(o, self)
  self.__index = self
  o.title = title
  o.rows = {}
  o.selected = 1
  o.capacityText = ""
  o.categoryId = "misc"
  o.showCategory = false
  return o
end

function BGUI.InventoryListPane:setRows(rows)
  self.rows = rows or {}
  if self.selected > #self.rows then
    self.selected = math.max(1, #self.rows)
  end
  if #self.rows == 0 then
    self.selected = 1
  end
end

function BGUI.InventoryListPane:moveSelection(delta)
  if #self.rows == 0 then return end
  self.selected = ((self.selected - 1 + delta) % #self.rows) + 1
end

function BGUI.InventoryListPane:getSelected()
  return self.rows[self.selected]
end

function BGUI.InventoryListPane:prerender()
  self:drawRect(0, 0, self.width, self.height, 0.85, 0.05, 0.05, 0.05)
  self:drawText(self.title, 8, 6, 1, 1, 1, 1, UIFont.Medium)
  if self.capacityText ~= "" then
    self:drawText(BGUI.Strings.capacity .. ": " .. self.capacityText, 8, 28, 0.8, 0.8, 0.8, 1, UIFont.Small)
  end
  if self.showCategory then
    self:drawText(BGUI.CategoryFilter.label(self.categoryId), 8, 46, 0.9, 0.9, 0.6, 1, UIFont.Small)
  end
  local y = self.showCategory and 66 or 48
  for i = 1, #self.rows do
    local row = self.rows[i]
    local label = row.label or row.type or "?"
    if i == self.selected then
      self:drawRect(4, y - 2, self.width - 8, 18, 0.35, 0.2, 0.45, 0.2)
    end
    self:drawText(label, 12, y, 1, 1, 1, 1, UIFont.Small)
    y = y + 18
  end
end
