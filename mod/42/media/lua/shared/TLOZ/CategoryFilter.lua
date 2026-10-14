-- media/lua/shared/TLOZ/CategoryFilter.lua
TLOZ = TLOZ or {}
require "TLOZ/Strings_PT"

local ORDER = {
  "weapons", "ammo", "clothes", "food", "water",
  "medical", "containers", "tools", "misc",
}

local PATTERNS = {
  weapons = { "Axe", "Bat", "Knife", "Gun", "Rifle", "Pistol", "Shotgun", "Machete", "Spear" },
  ammo = { "Bullet", "ShotgunShell", "Ammo" },
  clothes = { "Tshirt", "Shirt", "Pants", "Socks", "Jacket", "Hat", "Shoes", "Hoodie" },
  food = { "Apple", "Banana", "Burger", "Canned", "Chips", "Pizza", "Steak", "Bread" },
  water = { "Water", "Bottle" },
  medical = { "Bandage", "Pills", "Alcohol", "Suture", "Disinfectant", "FirstAid" },
  containers = { "Bag", "Backpack", "Fanny", "Purse", "Satchel" },
  tools = { "Hammer", "Screwdriver", "Wrench", "Saw", "Torch", "Lighter", "TinOpener" },
}

local function match(typeName, list)
  for i = 1, #list do
    if string.find(typeName, list[i], 1, true) then return true end
  end
  return false
end

local CategoryFilter = {}
CategoryFilter.ORDER = ORDER

function CategoryFilter.classify(itemType)
  local name = itemType or ""
  for _, cat in ipairs(ORDER) do
    if cat ~= "misc" and PATTERNS[cat] and match(name, PATTERNS[cat]) then
      return cat
    end
  end
  return "misc"
end

function CategoryFilter.filter(items, categoryId)
  local out = {}
  for i = 1, #items do
    if CategoryFilter.classify(items[i].type) == categoryId then
      out[#out + 1] = items[i]
    end
  end
  return out
end

function CategoryFilter.cycle(currentId, delta)
  local idx = 1
  for i = 1, #ORDER do
    if ORDER[i] == currentId then idx = i break end
  end
  local n = #ORDER
  local nextIdx = ((idx - 1 + delta) % n) + 1
  if nextIdx < 1 then nextIdx = nextIdx + n end
  return ORDER[nextIdx]
end

function CategoryFilter.label(categoryId)
  local map = {
    weapons = TLOZ.Strings.categoryWeapons,
    ammo = TLOZ.Strings.categoryAmmo,
    clothes = TLOZ.Strings.categoryClothes,
    food = TLOZ.Strings.categoryFood,
    water = TLOZ.Strings.categoryWater,
    medical = TLOZ.Strings.categoryMedical,
    containers = TLOZ.Strings.categoryContainers,
    tools = TLOZ.Strings.categoryTools,
    misc = TLOZ.Strings.categoryMisc,
  }
  return map[categoryId] or categoryId
end

TLOZ.CategoryFilter = CategoryFilter
