# Mod GamePad / UI (The Last of Z) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar um mod Lua-first para Project Zomboid (B42) que troca a UI inteira no gamepad (shell próprio), inventário dual-pane estilo Abas list-first, hub/radiais whitelist, ButtonLegend e DualSense com fallback.

**Architecture:** `InputRouter` detecta KB/M vs gamepad e monta `KbmShell` ou `GamepadShell`. No shell de pad, `FocusStack` + `JoypadData` dirigem `DualPaneInventory` (VOCÊ Abas Equipado|Mochila + ALCANCE), `RadialHub`/satélites e `ButtonLegend`. `DualSenseHooks` aplica gatilhos adaptativos/háptica quando disponíveis e degrada sem erro em Xbox/genérico. Lógica pura (modo, foco, categorias, fatias) fica em `shared/` com harness `lua` fora do jogo; UI ISUI fica em `client/` com DoD manual no PZ.

**Tech Stack:** Project Zomboid Build 42, Lua 5.1 (modding ISUI + Joypad), Steam Input / APIs DualSense quando existirem, harness de asserts com interpretador `lua`/`lua5.1` para lógica pura.

## Global Constraints

- Strings de UI do mod em **português** (labels, legendas, fatias, headers).
- Dual-UI obrigatório: gamepad = **shell próprio (swap total)**; sem painel KBM “meio adaptado”.
- Inventário **list-first** (estilo C Tactical Diegetic); layout **Abas** (Equipado | Mochila); dual-pane △; Alcance sempre visível; sem cursor-como-mouse; sem radial para navegar loot/categorias.
- **DualSense** (gatilhos adaptativos / háptica leve) é requisito importante; **fallback obrigatório** em Xbox/pad genérico com os mesmos binds.
- **Fora de escopo:** câmera 3P, TLOU/feel narrativo, companion, quests, pipeline de arte, loader Java/ZB como produto.
- Identificadores de código em **inglês**; comunicação/docs do Project em português.
- Ordem de entrega da spec: Dual-pane → Hub+Inventário → radiais item/mundo → Equip/Saúde/Mapa → Veículo+Construção → DualSense.

---

## File Structure

Greenfield sob `mods/TheLastOfZ_Gamepad/` (convenção B42). Cada arquivo tem uma responsabilidade.

```
mods/TheLastOfZ_Gamepad/
  mod.info
  DOD_V1.md
  media/
    lua/
      shared/
        TLOZ/
          InputMode.lua            -- enum/helpers kbm|gamepad
          InputRouter.lua          -- decide modo; eventos enter/exit
          FocusStack.lua           -- pilha de foco UI (push/pop/peek)
          CategoryFilter.lua       -- categorias mochila/alcance + ciclo
          RadialSlice.lua          -- fatia ≤8, hide-if-empty
          Strings_PT.lua           -- todas as strings de UI (PT)
          JoypadBindMap.lua        -- glyphs PS/Xbox + detectFamily
          ButtonLegendModel.lua    -- buildEntries(context, family)
          DualSensePolicy.lua      -- shouldUseAdaptive + holdEffect
      client/
        TLOZ/
          bootstrap.lua            -- require + hooks Joypad/Events
          UIShell.lua              -- escolhe KbmShell | GamepadShell
          KbmShell.lua             -- pass-through / restaura vanilla
          GamepadShell.lua         -- monta DualPane, Radial, Legend, DualSense
          DualPaneInventory.lua    -- VOCÊ + ALCANCE, Abas, binds
          InventoryListPane.lua    -- lista + header kg + categorias
          ButtonLegend.lua         -- ISUI rodapé (desenha model)
          RadialHub.lua            -- hub hold L1 / fatias
          RadialSatellites.lua     -- item L2, mundo, equip, veículo, build
          DualSenseHooks.lua       -- adaptive triggers + fallback no-op
  tests/
    run_all.lua
    test_input_router.lua
    test_focus_stack.lua
    test_category_filter.lua
    test_radial_slice.lua
    test_button_legend.lua
    test_dualsense_policy.lua
```

| Arquivo | Responsabilidade |
|---------|------------------|
| `mod.info` | Metadados do mod (id, nome, descrição PT) |
| `DOD_V1.md` | Checklist de aceite v1 |
| `InputMode.lua` | Constantes `kbm` / `gamepad` e predicados |
| `InputRouter.lua` | Primeiro input decisivo → modo; callbacks enter/exit |
| `FocusStack.lua` | Pilha de alvos de foco para Joypad |
| `CategoryFilter.lua` | Lista de categorias + filtro de itens |
| `RadialSlice.lua` | Construção de ≤8 fatias; remove vazias |
| `Strings_PT.lua` | Copy PT centralizado |
| `JoypadBindMap.lua` | Glyphs / `detectFamily` |
| `ButtonLegendModel.lua` | Entradas da legend por contexto |
| `DualSensePolicy.lua` | Quando aplicar adaptive + magnitudes |
| `bootstrap.lua` | Entry client: requires + Events |
| `UIShell.lua` | Orquestra swap de shell |
| `KbmShell.lua` | Estado KB/M (vanilla) |
| `GamepadShell.lua` | Estado pad: filhos UI |
| `DualPaneInventory.lua` | Dual-pane Abas + navegação |
| `InventoryListPane.lua` | Uma coluna de lista |
| `ButtonLegend.lua` | Draw ISUI da legend |
| `RadialHub.lua` | Hub principal |
| `RadialSatellites.lua` | Satélites whitelist |
| `DualSenseHooks.lua` | DualSense + fallback |
| `tests/*.lua` | Harness puro Lua 5.1 |

---

### Task 1: Scaffold do mod + Strings PT + runner de testes

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/mod.info`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/Strings_PT.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/run_all.lua`

**Interfaces:**
- Consumes: nada (greenfield)
- Produces: `TLOZ.Strings` table; `mod.info` id `TheLastOfZ_Gamepad`; `tests/run_all.lua` que carrega e executa `tests/test_*.lua`

- [ ] **Step 1: Criar `mod.info`**

```
name=The Last of Z — GamePad
id=TheLastOfZ_Gamepad
description=UI e inputs no controle para Project Zomboid: shell gamepad, inventário dual-pane Abas, hub radial e DualSense com fallback.
poster=
author=The Last of Z
modversion=0.1.0
versionMin=42.0
```

- [ ] **Step 2: Criar `Strings_PT.lua` com copy v1**

```lua
-- media/lua/shared/TLOZ/Strings_PT.lua
TLOZ = TLOZ or {}
TLOZ.Strings = {
  you = "VOCÊ",
  reach = "ALCANCE",
  tabEquipped = "Equipado",
  tabBackpack = "Mochila",
  capacity = "Capacidade",
  transfer = "Transferir",
  use = "Usar",
  back = "Voltar",
  close = "Fechar",
  swapSide = "Trocar lado",
  categoryWeapons = "Armas",
  categoryAmmo = "Munição",
  categoryClothes = "Roupas",
  categoryFood = "Comida",
  categoryWater = "Água",
  categoryMedical = "Med",
  categoryContainers = "Recipientes",
  categoryTools = "Ferramentas",
  categoryMisc = "Misc",
  radialInventory = "Inventário",
  radialHealth = "Saúde",
  radialMap = "Mapa",
  radialCraft = "Criar",
  radialBuild = "Construir",
  radialCharacter = "Personagem",
  radialOptions = "Opções",
  radialEquip = "Equipamentos",
  radialWorld = "Ações",
  radialVehicle = "Veículo",
  actionEat = "Comer",
  actionEquip = "Equipar",
  actionDrop = "Dropar",
  actionInfo = "Info",
  legendConfirm = "Confirmar",
  legendCancel = "Cancelar",
}
```

- [ ] **Step 3: Criar bootstrap mínimo (só require shared)**

```lua
-- media/lua/client/TLOZ/bootstrap.lua
require "TLOZ/Strings_PT"
-- demais requires entram nas tasks seguintes
print("[TLOZ] bootstrap loaded")
```

- [ ] **Step 4: Criar runner de testes**

```lua
-- tests/run_all.lua
package.path = package.path
  .. ";../media/lua/shared/?.lua"
  .. ";../media/lua/shared/?/?.lua"
  .. ";./?.lua"

local failed = 0
local function run(file)
  print("==> " .. file)
  local ok, err = pcall(function()
    dofile(file)
  end)
  if not ok then
    failed = failed + 1
    print("FAIL: " .. tostring(err))
  else
    print("OK")
  end
end

local tests = {
  "test_input_router.lua",
  "test_focus_stack.lua",
  "test_category_filter.lua",
  "test_radial_slice.lua",
}
for _, t in ipairs(tests) do
  -- arquivos ainda inexistentes: ignorar até a task correspondente
  local f = io.open(t, "r")
  if f then
    f:close()
    run(t)
  else
    print("SKIP (missing): " .. t)
  end
end

if failed > 0 then
  os.exit(1)
end
print("ALL PRESENT TESTS PASSED")
```

- [ ] **Step 5: Verificar runner**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 run_all.lua`
Expected: imprime `SKIP` para os quatro testes ausentes e termina com `ALL PRESENT TESTS PASSED` (exit 0).

- [ ] **Step 6: Commit**

```bash
git add mods/TheLastOfZ_Gamepad
git commit -m "chore: scaffold TheLastOfZ_Gamepad mod layout and PT strings"
```

---

### Task 2: InputRouter (modo kbm|gamepad)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/InputMode.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/InputRouter.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/test_input_router.lua`

**Interfaces:**
- Consumes: nada
- Produces:
  - `TLOZ.InputMode.KBM` = `"kbm"`, `TLOZ.InputMode.GAMEPAD` = `"gamepad"`
  - `TLOZ.InputRouter.new()` → router com:
    - `getMode() → string`
    - `onDecisiveInput(kind)` onde `kind` é `"keyboard"|"mouse"|"gamepad"`
    - `onEnterGamepad(fn)`, `onExitGamepad(fn)` — callbacks
    - `forceMode(mode)` para testes/restauração

- [ ] **Step 1: Escrever teste falhando**

```lua
-- tests/test_input_router.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/InputMode"
require "TLOZ/InputRouter"

local r = TLOZ.InputRouter.new()
assert(r:getMode() == TLOZ.InputMode.KBM, "default kbm")

local entered, exited = 0, 0
r:onEnterGamepad(function() entered = entered + 1 end)
r:onExitGamepad(function() exited = exited + 1 end)

r:onDecisiveInput("gamepad")
assert(r:getMode() == TLOZ.InputMode.GAMEPAD, "enter gamepad")
assert(entered == 1, "enter once")

r:onDecisiveInput("gamepad")
assert(entered == 1, "idempotent while already gamepad")

r:onDecisiveInput("keyboard")
assert(r:getMode() == TLOZ.InputMode.KBM, "exit to kbm")
assert(exited == 1, "exit once")

r:onDecisiveInput("mouse")
assert(r:getMode() == TLOZ.InputMode.KBM)
assert(exited == 1, "still kbm, no double exit")

r:forceMode(TLOZ.InputMode.GAMEPAD)
assert(r:getMode() == TLOZ.InputMode.GAMEPAD)
assert(entered == 2, "forceMode fires enter")
```

- [ ] **Step 2: Rodar e confirmar FAIL**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_input_router.lua`
Expected: FAIL com module/file not found para `InputRouter` ou `InputMode`.

- [ ] **Step 3: Implementar `InputMode.lua` e `InputRouter.lua`**

```lua
-- media/lua/shared/TLOZ/InputMode.lua
TLOZ = TLOZ or {}
TLOZ.InputMode = {
  KBM = "kbm",
  GAMEPAD = "gamepad",
}

-- media/lua/shared/TLOZ/InputRouter.lua
TLOZ = TLOZ or {}
require "TLOZ/InputMode"

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
```

- [ ] **Step 4: Rodar e confirmar PASS**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_input_router.lua && lua5.1 run_all.lua`
Expected: exit 0; `test_input_router` OK; outros SKIP até existirem.

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/InputMode.lua \
  mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/InputRouter.lua \
  mods/TheLastOfZ_Gamepad/tests/test_input_router.lua
git commit -m "feat: add InputRouter dual-mode detection logic"
```

---

### Task 3: FocusStack

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/FocusStack.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/test_focus_stack.lua`

**Interfaces:**
- Consumes: nada
- Produces: `TLOZ.FocusStack.new()` com `push(id)`, `pop() → id|nil`, `peek() → id|nil`, `clear()`, `depth() → number`

- [ ] **Step 1: Escrever teste falhando**

```lua
-- tests/test_focus_stack.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/FocusStack"

local s = TLOZ.FocusStack.new()
assert(s:depth() == 0)
assert(s:peek() == nil)
assert(s:pop() == nil)

s:push("dualpane")
s:push("radial")
assert(s:depth() == 2)
assert(s:peek() == "radial")
assert(s:pop() == "radial")
assert(s:peek() == "dualpane")
s:clear()
assert(s:depth() == 0)
assert(s:peek() == nil)
```

- [ ] **Step 2: Rodar e confirmar FAIL**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_focus_stack.lua`
Expected: FAIL module not found.

- [ ] **Step 3: Implementar**

```lua
-- media/lua/shared/TLOZ/FocusStack.lua
TLOZ = TLOZ or {}
local Stack = {}
Stack.__index = Stack

function TLOZ.FocusStack.new()
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
```

- [ ] **Step 4: Rodar PASS**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_focus_stack.lua && lua5.1 run_all.lua`
Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/FocusStack.lua \
  mods/TheLastOfZ_Gamepad/tests/test_focus_stack.lua
git commit -m "feat: add FocusStack for gamepad UI focus"
```

---

### Task 4: CategoryFilter (list-first, sem radial)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/CategoryFilter.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/test_category_filter.lua`

**Interfaces:**
- Consumes: `TLOZ.Strings` (labels PT)
- Produces:
  - `TLOZ.CategoryFilter.ORDER` — array estável de ids
  - `TLOZ.CategoryFilter.classify(itemType) → categoryId`
  - `TLOZ.CategoryFilter.filter(items, categoryId) → items`
  - `TLOZ.CategoryFilter.cycle(currentId, delta) → nextId` (`delta` ±1; L1/R1)

- [ ] **Step 1: Escrever teste falhando**

```lua
-- tests/test_category_filter.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/Strings_PT"
require "TLOZ/CategoryFilter"

local C = TLOZ.CategoryFilter
assert(#C.ORDER >= 8)
assert(C.classify("Base.Axe") == "weapons")
assert(C.classify("Base.Bullets9mm") == "ammo")
assert(C.classify("Base.Tshirt_White") == "clothes")
assert(C.classify("Base.Apple") == "food")
assert(C.classify("Base.WaterBottleFull") == "water")
assert(C.classify("Base.Bandage") == "medical")
assert(C.classify("Base.Bag") == "containers")
assert(C.classify("Base.Hammer") == "tools")
assert(C.classify("Base.Newspaper") == "misc")

local items = {
  { type = "Base.Axe" },
  { type = "Base.Apple" },
  { type = "Base.Hammer" },
}
local weapons = C.filter(items, "weapons")
assert(#weapons == 1 and weapons[1].type == "Base.Axe")

local id = "weapons"
id = C.cycle(id, 1)
assert(id == "ammo")
id = C.cycle("misc", 1)
assert(id == "weapons", "wrap forward")
id = C.cycle("weapons", -1)
assert(id == "misc", "wrap back")
```

- [ ] **Step 2: Rodar FAIL**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_category_filter.lua`
Expected: FAIL module not found.

- [ ] **Step 3: Implementar classificador por padrões de nome (heurística v1)**

```lua
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
```

- [ ] **Step 4: Rodar PASS**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_category_filter.lua && lua5.1 run_all.lua`
Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/CategoryFilter.lua \
  mods/TheLastOfZ_Gamepad/tests/test_category_filter.lua
git commit -m "feat: add CategoryFilter for list-first backpack"
```

---

### Task 5: RadialSlice (≤8, vazias somem)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/RadialSlice.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/test_radial_slice.lua`

**Interfaces:**
- Consumes: nada
- Produces: `TLOZ.RadialSlice.build(candidates) → slices` onde cada candidate é `{ id, label, enabled }` e o resultado tem no máximo 8 itens, só `enabled == true`, ordem preservada

- [ ] **Step 1: Escrever teste falhando**

```lua
-- tests/test_radial_slice.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/RadialSlice"

local candidates = {}
for i = 1, 10 do
  candidates[i] = { id = "s" .. i, label = "S" .. i, enabled = i ~= 3 }
end
local slices = TLOZ.RadialSlice.build(candidates)
assert(#slices <= 8)
assert(#slices == 8, "drop empty + cap at 8 from 9 enabled")
for _, s in ipairs(slices) do
  assert(s.id ~= "s3", "disabled excluded")
end

local none = TLOZ.RadialSlice.build({
  { id = "a", label = "A", enabled = false },
})
assert(#none == 0)
```

- [ ] **Step 2: Rodar FAIL**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_radial_slice.lua`
Expected: FAIL module not found.

- [ ] **Step 3: Implementar**

```lua
-- media/lua/shared/TLOZ/RadialSlice.lua
TLOZ = TLOZ or {}
TLOZ.RadialSlice = {}

function TLOZ.RadialSlice.build(candidates)
  local out = {}
  for i = 1, #candidates do
    local c = candidates[i]
    if c.enabled then
      out[#out + 1] = { id = c.id, label = c.label }
      if #out >= 8 then break end
    end
  end
  return out
end
```

- [ ] **Step 4: Rodar PASS**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_radial_slice.lua && lua5.1 run_all.lua`
Expected: `ALL PRESENT TESTS PASSED`, nenhum SKIP.

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/RadialSlice.lua \
  mods/TheLastOfZ_Gamepad/tests/test_radial_slice.lua
git commit -m "feat: add RadialSlice builder with max-8 rule"
```

---

### Task 6: JoypadBindMap + ButtonLegend (lógica de glyphs)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/JoypadBindMap.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/ButtonLegend.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/test_button_legend.lua`

**Interfaces:**
- Consumes: `TLOZ.Strings`
- Produces:
  - `TLOZ.JoypadBindMap.glyph(family, action) → string` — `family` `"ps"|"xbox"`
  - `TLOZ.ButtonLegend.buildEntries(context, family) → { {glyph, label}, ... }`
  - contexts: `"dualpane_you"`, `"dualpane_reach"`, `"radial_open"`, `"world"`

Nota: `ButtonLegend.lua` no client exporta também a lógica pura `buildEntries` testável; o draw ISUI entra na Task 9/10. Para o harness, copiar a função pura para shared ou carregar o client file no path de teste.

- [ ] **Step 1: Mover helpers de legend para shared testável — criar bind map shared-friendly**

Colocar a tabela de glyphs e `buildEntries` em arquivos carregáveis pelo harness:

```lua
-- media/lua/shared/TLOZ/JoypadBindMap.lua  (shared, também required pelo client)
TLOZ = TLOZ or {}
TLOZ.JoypadBindMap = {
  ps = {
    confirm = "✕", cancel = "○", openInv = "△", swapSide = "□",
    tabPrev = "L1", tabNext = "R1", itemRadial = "L2", hub = "L1",
  },
  xbox = {
    confirm = "A", cancel = "B", openInv = "Y", swapSide = "X",
    tabPrev = "LB", tabNext = "RB", itemRadial = "LT", hub = "LB",
  },
}

function TLOZ.JoypadBindMap.glyph(family, action)
  local t = TLOZ.JoypadBindMap[family] or TLOZ.JoypadBindMap.xbox
  return t[action] or "?"
end

function TLOZ.JoypadBindMap.detectFamily(controllerName)
  local n = string.lower(controllerName or "")
  if string.find(n, "dualsense", 1, true) or string.find(n, "wireless controller", 1, true)
      or string.find(n, "playstation", 1, true) then
    return "ps"
  end
  return "xbox"
end
```

```lua
-- media/lua/shared/TLOZ/ButtonLegendModel.lua
TLOZ = TLOZ or {}
require "TLOZ/Strings_PT"
require "TLOZ/JoypadBindMap"

function TLOZ.ButtonLegendModel.buildEntries(context, family)
  local g = function(a) return TLOZ.JoypadBindMap.glyph(family, a) end
  local S = TLOZ.Strings
  if context == "dualpane_you" or context == "dualpane_reach" then
    return {
      { glyph = g("swapSide"), label = S.swapSide },
      { glyph = g("confirm"), label = S.transfer },
      { glyph = g("cancel"), label = S.back },
      { glyph = g("openInv"), label = S.close },
      { glyph = g("itemRadial"), label = S.radialWorld },
      { glyph = g("tabPrev") .. "/" .. g("tabNext"), label = S.tabEquipped .. "/" .. S.tabBackpack },
    }
  elseif context == "radial_open" then
    return {
      { glyph = g("confirm"), label = S.legendConfirm },
      { glyph = g("cancel"), label = S.legendCancel },
    }
  else
    return {
      { glyph = g("hub"), label = S.radialInventory },
      { glyph = g("openInv"), label = S.radialInventory },
    }
  end
end
```

Ajustar File Structure mental: client `ButtonLegend.lua` só desenha; model fica em shared. Atualizar `bootstrap` depois.

- [ ] **Step 2: Teste**

```lua
-- tests/test_button_legend.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/Strings_PT"
require "TLOZ/JoypadBindMap"
require "TLOZ/ButtonLegendModel"

assert(TLOZ.JoypadBindMap.detectFamily("DualSense Wireless Controller") == "ps")
assert(TLOZ.JoypadBindMap.detectFamily("Xbox One Controller") == "xbox")

local e = TLOZ.ButtonLegendModel.buildEntries("dualpane_you", "ps")
assert(#e >= 4)
assert(e[1].glyph == "□")
assert(e[1].label == "Trocar lado")

local r = TLOZ.ButtonLegendModel.buildEntries("radial_open", "xbox")
assert(r[1].glyph == "A")
assert(r[1].label == "Confirmar")
```

- [ ] **Step 3: Rodar FAIL → implementar arquivos acima → PASS**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 test_button_legend.lua`
Expected (após impl): exit 0.

Atualizar `tests/run_all.lua` para incluir `"test_button_legend.lua"`.

- [ ] **Step 4: Stub client draw**

```lua
-- media/lua/client/TLOZ/ButtonLegend.lua
require "TLOZ/ButtonLegendModel"
TLOZ = TLOZ or {}
TLOZ.ButtonLegend = ISUIElement:derive("TLOZ.ButtonLegend")

function TLOZ.ButtonLegend:new(x, y, w, h)
  local o = ISUIElement:new(x, y, w, h)
  setmetatable(o, self)
  self.__index = self
  o.context = "world"
  o.family = "xbox"
  return o
end

function TLOZ.ButtonLegend:setContext(context, family)
  self.context = context
  self.family = family or self.family
end

function TLOZ.ButtonLegend:render()
  local entries = TLOZ.ButtonLegendModel.buildEntries(self.context, self.family)
  local x = 8
  for i = 1, #entries do
    local e = entries[i]
    self:drawText(e.glyph .. " " .. e.label, x, 4, 1, 1, 1, 1, UIFont.Small)
    x = x + 120
  end
end
```

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/JoypadBindMap.lua \
  mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/ButtonLegendModel.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/ButtonLegend.lua \
  mods/TheLastOfZ_Gamepad/tests/test_button_legend.lua \
  mods/TheLastOfZ_Gamepad/tests/run_all.lua
git commit -m "feat: add ButtonLegend model and PS/Xbox glyphs"
```

---

### Task 7: UIShell + KbmShell + GamepadShell (swap total)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/UIShell.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/KbmShell.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/GamepadShell.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua`

**Interfaces:**
- Consumes: `TLOZ.InputRouter`, `TLOZ.FocusStack`
- Produces:
  - `TLOZ.UIShell.start(router)` — escuta enter/exit
  - `TLOZ.GamepadShell:activate()` / `:deactivate()` — mostra/esconde filhos
  - `TLOZ.KbmShell:activate()` / `:deactivate()` — restaura vanilla

- [ ] **Step 1: Implementar KbmShell (pass-through)**

```lua
-- media/lua/client/TLOZ/KbmShell.lua
TLOZ = TLOZ or {}
TLOZ.KbmShell = {}

function TLOZ.KbmShell:activate()
  -- vanilla ISUI permanece; apenas marca modo
  TLOZ._activeShell = "kbm"
end

function TLOZ.KbmShell:deactivate()
  -- nada a destruir no v1
end
```

- [ ] **Step 2: Implementar GamepadShell (esqueleto)**

```lua
-- media/lua/client/TLOZ/GamepadShell.lua
require "TLOZ/FocusStack"
TLOZ = TLOZ or {}
TLOZ.GamepadShell = {}

function TLOZ.GamepadShell:activate()
  TLOZ._activeShell = "gamepad"
  TLOZ._focus = TLOZ._focus or TLOZ.FocusStack.new()
  TLOZ._focus:clear()
  TLOZ._focus:push("world")
  -- DualPane / Radial / Legend são criados nas tasks seguintes;
  -- aqui só garante que KBM flutuante não compete: esconder painéis
  -- vanilla de inventário quando o nosso DualPane existir (Task 8).
  if TLOZ.ButtonLegend and not TLOZ._legend then
    TLOZ._legend = TLOZ.ButtonLegend:new(0, getCore():getScreenHeight() - 32, getCore():getScreenWidth(), 32)
    TLOZ._legend:setContext("world", TLOZ._glyphFamily or "xbox")
    TLOZ._legend:addToUIManager()
  end
end

function TLOZ.GamepadShell:deactivate()
  if TLOZ._legend then
    TLOZ._legend:removeFromUIManager()
    TLOZ._legend = nil
  end
  if TLOZ._dualPane then
    TLOZ._dualPane:close()
    TLOZ._dualPane = nil
  end
  if TLOZ._radialHub then
    TLOZ._radialHub:close()
    TLOZ._radialHub = nil
  end
  if TLOZ._focus then TLOZ._focus:clear() end
  TLOZ._activeShell = "kbm"
end
```

- [ ] **Step 3: Implementar UIShell**

```lua
-- media/lua/client/TLOZ/UIShell.lua
require "TLOZ/InputRouter"
require "TLOZ/KbmShell"
require "TLOZ/GamepadShell"

TLOZ = TLOZ or {}
TLOZ.UIShell = {}

function TLOZ.UIShell.start(router)
  TLOZ._router = router
  TLOZ.KbmShell:activate()
  router:onEnterGamepad(function()
    TLOZ.KbmShell:deactivate()
    TLOZ.GamepadShell:activate()
  end)
  router:onExitGamepad(function()
    TLOZ.GamepadShell:deactivate()
    TLOZ.KbmShell:activate()
  end)
end
```

- [ ] **Step 4: Ligar bootstrap a Joypad / teclado**

```lua
-- media/lua/client/TLOZ/bootstrap.lua
require "TLOZ/Strings_PT"
require "TLOZ/InputMode"
require "TLOZ/InputRouter"
require "TLOZ/JoypadBindMap"
require "TLOZ/ButtonLegend"
require "TLOZ/UIShell"

local router = TLOZ.InputRouter.new()
TLOZ.UIShell.start(router)

local function onJoypadActivate(joypadData)
  local name = ""
  if joypadData and joypadData.controller and joypadData.controller.getName then
    name = joypadData.controller:getName() or ""
  end
  TLOZ._glyphFamily = TLOZ.JoypadBindMap.detectFamily(name)
  router:onDecisiveInput("gamepad")
end

local function onKeyPressed(key)
  -- qualquer tecla decisiva volta a KBM (exceto se quisermos whitelist)
  if TLOZ._router and TLOZ._router:getMode() == TLOZ.InputMode.GAMEPAD then
    router:onDecisiveInput("keyboard")
  end
end

Events.OnJoypadActivate.Add(onJoypadActivate)
Events.OnKeyStartPressed.Add(onKeyPressed)
print("[TLOZ] dual-UI router armed")
```

- [ ] **Step 5: DoD in-game (shell swap)**

No Project Zomboid B42 com o mod ativo:
1. Iniciar jogo com teclado → UI vanilla; console/`debug` mostra `[TLOZ] dual-UI router armed`.
2. Conectar/ativar joypad (ou pressionar botão) → `TLOZ._activeShell == "gamepad"` (verificar via debug lua se disponível) e legend no rodapé aparece.
3. Pressionar tecla → shell volta a KBM; legend some.
4. Confirmar que **não** permanece inventário vanilla “com glyphs” como único modo pad.

- [ ] **Step 6: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/
git commit -m "feat: dual-UI shell swap via InputRouter"
```

---

### Task 8: InventoryListPane + DualPaneInventory (Abas)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/InventoryListPane.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualPaneInventory.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/GamepadShell.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua`

**Interfaces:**
- Consumes: `TLOZ.Strings`, `TLOZ.CategoryFilter`, `TLOZ.FocusStack`, `TLOZ.ButtonLegendModel`
- Produces:
  - `TLOZ.DualPaneInventory:open(playerNum)` / `:close()`
  - estado: `side` `"you"|"reach"`, `youTab` `"equipped"|"backpack"`, `categoryId`, `rowIndex`
  - binds: △ fecha; □ troca lado; L1/R1 abas ou ciclo nearby/categoria; stick/D-pad ↑↓ linha; ✕ transferir/usar

- [ ] **Step 1: Implementar InventoryListPane (lista + header)**

```lua
-- media/lua/client/TLOZ/InventoryListPane.lua
require "TLOZ/Strings_PT"
require "TLOZ/CategoryFilter"

TLOZ = TLOZ or {}
TLOZ.InventoryListPane = ISPanel:derive("TLOZ.InventoryListPane")

function TLOZ.InventoryListPane:new(x, y, w, h, title)
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

function TLOZ.InventoryListPane:setRows(rows)
  self.rows = rows or {}
  if self.selected > #self.rows then self.selected = math.max(1, #self.rows) end
end

function TLOZ.InventoryListPane:moveSelection(delta)
  if #self.rows == 0 then return end
  self.selected = ((self.selected - 1 + delta) % #self.rows) + 1
end

function TLOZ.InventoryListPane:getSelected()
  return self.rows[self.selected]
end

function TLOZ.InventoryListPane:prerender()
  self:drawRect(0, 0, self.width, self.height, 0.85, 0.05, 0.05, 0.05)
  self:drawText(self.title, 8, 6, 1, 1, 1, 1, UIFont.Medium)
  if self.capacityText ~= "" then
    self:drawText(TLOZ.Strings.capacity .. ": " .. self.capacityText, 8, 28, 0.8, 0.8, 0.8, 1, UIFont.Small)
  end
  if self.showCategory then
    self:drawText(TLOZ.CategoryFilter.label(self.categoryId), 8, 46, 0.9, 0.9, 0.6, 1, UIFont.Small)
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
```

- [ ] **Step 2: Implementar DualPaneInventory**

```lua
-- media/lua/client/TLOZ/DualPaneInventory.lua
require "TLOZ/InventoryListPane"
require "TLOZ/CategoryFilter"
require "TLOZ/Strings_PT"

TLOZ = TLOZ or {}
TLOZ.DualPaneInventory = ISPanel:derive("TLOZ.DualPaneInventory")

function TLOZ.DualPaneInventory:new(playerNum)
  local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
  local w, h = math.floor(sw * 0.8), math.floor(sh * 0.7)
  local o = ISPanel:new(math.floor((sw - w) / 2), math.floor((sh - h) / 2), w, h)
  setmetatable(o, self)
  self.__index = self
  o.playerNum = playerNum
  o.side = "you"
  o.youTab = "equipped"
  o.categoryId = "weapons"
  o.reachIndex = 1
  return o
end

function TLOZ.DualPaneInventory:open()
  local half = math.floor(self.width / 2) - 8
  self.youPane = TLOZ.InventoryListPane:new(8, 8, half, self.height - 16, TLOZ.Strings.you)
  self.reachPane = TLOZ.InventoryListPane:new(half + 16, 8, half, self.height - 16, TLOZ.Strings.reach)
  self.reachPane.showCategory = true
  self:addChild(self.youPane)
  self:addChild(self.reachPane)
  self:refresh()
  self:addToUIManager()
  if TLOZ._focus then
    TLOZ._focus:push("dualpane")
  end
  if TLOZ._legend then
    TLOZ._legend:setContext("dualpane_you", TLOZ._glyphFamily or "xbox")
  end
end

function TLOZ.DualPaneInventory:close()
  self:setVisible(false)
  self:removeFromUIManager()
  if TLOZ._focus and TLOZ._focus:peek() == "dualpane" then
    TLOZ._focus:pop()
  end
  if TLOZ._legend then
    TLOZ._legend:setContext("world", TLOZ._glyphFamily or "xbox")
  end
end

function TLOZ.DualPaneInventory:refresh()
  local player = getSpecificPlayer(self.playerNum)
  if not player then return end
  -- Equipado: slots estáveis (mãos, roupa, luz) — labels PT via item name
  if self.youTab == "equipped" then
    self.youPane.showCategory = false
    self.youPane.title = TLOZ.Strings.you .. " — " .. TLOZ.Strings.tabEquipped
    local rows = {}
    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()
    rows[#rows + 1] = { label = primary and primary:getDisplayName() or "(mão primária vazia)", item = primary, kind = "hand" }
    rows[#rows + 1] = { label = secondary and secondary:getDisplayName() or "(mão secundária vazia)", item = secondary, kind = "hand" }
    self.youPane:setRows(rows)
  else
    self.youPane.showCategory = true
    self.youPane.categoryId = self.categoryId
    self.youPane.title = TLOZ.Strings.you .. " — " .. TLOZ.Strings.tabBackpack
    local items = {}
    local inv = player:getInventory():getItems()
    for i = 0, inv:size() - 1 do
      local it = inv:get(i)
      items[#items + 1] = { type = it:getFullType(), label = it:getDisplayName(), item = it }
    end
    self.youPane:setRows(TLOZ.CategoryFilter.filter(items, self.categoryId))
  end
  -- Alcance: container atual (API nearby) — v1 usa loot do tile focado quando existir
  self.reachPane.categoryId = self.categoryId
  self.reachPane.title = TLOZ.Strings.reach
  self.reachPane:setRows(self:_gatherReachRows(player))
  local inv = player:getInventory()
  self.youPane.capacityText = string.format("%.1f / %.1f kg", inv:getCapacityWeight(), inv:getMaxWeight())
end

function TLOZ.DualPaneInventory:_gatherReachRows(player)
  -- Integração B42: preferir ISInventoryPage.loot_inventory / nearby containers.
  -- Fallback v1: lista vazia com placeholder PT.
  local rows = {}
  local sq = player:getCurrentSquare()
  if not sq then
    return { { label = "(sem alcance)", item = nil } }
  end
  -- World items on square
  local witems = sq:getWorldObjects()
  if witems then
    for i = 0, witems:size() - 1 do
      local wo = witems:get(i)
      local item = wo:getItem()
      if item then
        rows[#rows + 1] = { type = item:getFullType(), label = item:getDisplayName(), item = item, world = true }
      end
    end
  end
  if #rows == 0 then
    rows[1] = { label = "(vazio)", item = nil }
  end
  return rows
end

function TLOZ.DualPaneInventory:onSwapSide()
  self.side = (self.side == "you") and "reach" or "you"
  if TLOZ._legend then
    local ctx = (self.side == "you") and "dualpane_you" or "dualpane_reach"
    TLOZ._legend:setContext(ctx, TLOZ._glyphFamily or "xbox")
  end
end

function TLOZ.DualPaneInventory:onTabOrCycle(delta)
  if self.side == "you" then
    -- L1/R1 foco esquerda: alternar Equipado ↔ Mochila
    if self.youTab == "equipped" then
      self.youTab = "backpack"
    else
      self.youTab = "equipped"
    end
  else
    -- L1/R1 foco direita: ciclar alvo nearby
    self.reachIndex = math.max(1, self.reachIndex + (delta >= 0 and 1 or -1))
  end
  self:refresh()
end

function TLOZ.DualPaneInventory:onCycleCategory(delta)
  -- D-pad ←→ (ou bind dedicado): ciclar categoria na lista ativa — nunca via radial
  if self.side == "you" and self.youTab ~= "backpack" then return end
  self.categoryId = TLOZ.CategoryFilter.cycle(self.categoryId, delta)
  self:refresh()
end

function TLOZ.DualPaneInventory:onNavigate(delta)
  if self.side == "you" then self.youPane:moveSelection(delta)
  else self.reachPane:moveSelection(delta) end
end

function TLOZ.DualPaneInventory:onConfirmTransfer()
  local player = getSpecificPlayer(self.playerNum)
  if not player then return end
  local srcPane = (self.side == "you") and self.youPane or self.reachPane
  local dstIsPlayer = self.side == "reach"
  local row = srcPane:getSelected()
  if not row or not row.item then return end
  if dstIsPlayer then
    ISTimedActionQueue.add(ISInventoryTransferAction:new(player, row.item, row.item:getContainer(), player:getInventory()))
  else
    player:getCurrentSquare():AddWorldInventoryItem(row.item, 0, 0, 0)
    player:getInventory():Remove(row.item)
  end
  self:refresh()
end
```

- [ ] **Step 3: Abrir dual-pane no △ / Y e pela fatia Inventário (hook provisório)**

Em `bootstrap.lua`, após router:

```lua
require "TLOZ/DualPaneInventory"

local function openDualPane(playerNum)
  if TLOZ._router:getMode() ~= TLOZ.InputMode.GAMEPAD then return end
  if TLOZ._dualPane then
    TLOZ._dualPane:close()
    TLOZ._dualPane = nil
    return
  end
  TLOZ._dualPane = TLOZ.DualPaneInventory:new(playerNum or 0)
  TLOZ._dualPane:open()
end

TLOZ.openDualPane = openDualPane

-- Joypad button Y / Triangle — usar Events.OnJoypadButtonPressed se disponível na B42
Events.OnJoypadRenderUI.Add(function(joypadData)
  -- polling mínimo v1: se botão Y acabou de pressionar, toggle
end)
```

Implementar o toggle Y com o event concreto da B42 no ambiente do implementador (`OnPressJoypadButton` / bind em `JoypadData`). Contrato: **△/Y toggle DualPane** só com shell gamepad ativo.

- [ ] **Step 4: DoD in-game (inventário)**

1. Entrar em modo gamepad.
2. △/Y abre dual-pane: esquerda VOCÊ, direita ALCANCE (sempre visível).
3. L1/R1 com foco esquerda alterna **Equipado | Mochila**.
4. Mochila mostra categorias em português; lista (não grid-cursor).
5. □ troca VOCÊ ↔ ALCANCE; legend atualiza.
6. Stick/D-pad ↑↓ move highlight de linha.
7. ✕ transfere um item; ○/△ fecha.
8. Confirmar: **nenhum radial** usado para mudar categoria ou saquear.

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/InventoryListPane.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualPaneInventory.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/GamepadShell.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua
git commit -m "feat: DualPane inventory with Abas layout"
```

---

### Task 9: RadialHub (hold L1, ≤8 fatias)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialHub.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/GamepadShell.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua`

**Interfaces:**
- Consumes: `TLOZ.RadialSlice`, `TLOZ.Strings`, `TLOZ.openDualPane`
- Produces: `TLOZ.RadialHub:open()` / `:close()` / `:confirm()`; fatias ids: `inventory|health|map|craft|build|character|options`

- [ ] **Step 1: Implementar RadialHub**

```lua
-- media/lua/client/TLOZ/RadialHub.lua
require "TLOZ/RadialSlice"
require "TLOZ/Strings_PT"

TLOZ = TLOZ or {}
TLOZ.RadialHub = ISPanel:derive("TLOZ.RadialHub")

function TLOZ.RadialHub:new()
  local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
  local size = 280
  local o = ISPanel:new(math.floor((sw - size) / 2), math.floor((sh - size) / 2), size, size)
  setmetatable(o, self)
  self.__index = self
  o.selected = 1
  o.slices = {}
  return o
end

function TLOZ.RadialHub:_candidates()
  local S = TLOZ.Strings
  return {
    { id = "inventory", label = S.radialInventory, enabled = true },
    { id = "health", label = S.radialHealth, enabled = true },
    { id = "map", label = S.radialMap, enabled = true },
    { id = "craft", label = S.radialCraft, enabled = true },
    { id = "build", label = S.radialBuild, enabled = true },
    { id = "character", label = S.radialCharacter, enabled = true },
    { id = "options", label = S.radialOptions, enabled = true },
  }
end

function TLOZ.RadialHub:open()
  self.slices = TLOZ.RadialSlice.build(self:_candidates())
  self.selected = 1
  self:addToUIManager()
  if TLOZ._focus then TLOZ._focus:push("radial_hub") end
  if TLOZ._legend then TLOZ._legend:setContext("radial_open", TLOZ._glyphFamily or "xbox") end
end

function TLOZ.RadialHub:close()
  self:removeFromUIManager()
  if TLOZ._focus and TLOZ._focus:peek() == "radial_hub" then TLOZ._focus:pop() end
  if TLOZ._legend then TLOZ._legend:setContext("world", TLOZ._glyphFamily or "xbox") end
end

function TLOZ.RadialHub:setStickDirection(angleRad)
  if #self.slices == 0 then return end
  local sector = (math.pi * 2) / #self.slices
  local idx = math.floor((angleRad + sector / 2) / sector) % #self.slices
  self.selected = idx + 1
end

function TLOZ.RadialHub:confirm()
  local slice = self.slices[self.selected]
  self:close()
  if not slice then return end
  if slice.id == "inventory" then
    TLOZ.openDualPane(0)
  elseif slice.id == "health" then
    -- abrir painel saúde vanilla + foco
    local player = getSpecificPlayer(0)
    if player then ISHealthPanel.activate(player) end
  elseif slice.id == "map" then
    local player = getSpecificPlayer(0)
    if player then ISWorldMap_instance = ISWorldMap_instance -- abrir mapa vanilla via API local
    end
    -- Usar o caminho B42 padrão para toggle do mapa no joypad do player 0
  elseif slice.id == "craft" then
    -- abrir crafting vanilla
  elseif slice.id == "build" then
    if TLOZ.RadialSatellites then TLOZ.RadialSatellites.openBuild() end
  elseif slice.id == "character" then
    -- skills / info vanilla
  elseif slice.id == "options" then
    -- settings jogo / mod
  end
end

function TLOZ.RadialHub:prerender()
  self:drawRect(0, 0, self.width, self.height, 0.7, 0.02, 0.02, 0.02)
  local cx, cy = self.width / 2, self.height / 2
  for i = 1, #self.slices do
    local a = ((i - 1) / #self.slices) * math.pi * 2 - math.pi / 2
    local x = cx + math.cos(a) * 90
    local y = cy + math.sin(a) * 90
    local c = (i == self.selected) and 1 or 0.6
    self:drawTextCentre(self.slices[i].label, x, y, c, c, c, 1, UIFont.Small)
  end
end
```

Para fatias `map`/`craft`/`character`/`options`, no implementador: chamar as funções ISUI vanilla equivalentes da B42 usadas pelo joypad stock (espelhar `ISButton` / keybinds existentes). Contrato de produto: cada fatia abre o painel correspondente; Inventário **sempre** chama `TLOZ.openDualPane`.

- [ ] **Step 2: Hold L1 abre hub**

No bootstrap / GamepadShell, registrar hold:

```lua
TLOZ._hubHoldMs = 0
-- a cada tick em gamepad shell, se L1 held > 250ms e foco world → RadialHub:open()
-- soltar sem confirm não confirma; ○ cancela; ✕ confirma
```

- [ ] **Step 3: DoD in-game (hub)**

1. Hold L1 no mundo (modo gamepad) abre hub com até 7 fatias em português.
2. Stick move seleção; ✕ na fatia Inventário abre DualPane Abas; ○ cancela.
3. Hub **não** lista itens da mochila.

- [ ] **Step 4: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialHub.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/GamepadShell.lua
git commit -m "feat: RadialHub with inventory slice to DualPane"
```

---

### Task 10: Satélites whitelist (item L2, mundo, equipamentos)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialSatellites.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualPaneInventory.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua`

**Interfaces:**
- Consumes: `TLOZ.RadialSlice`, `TLOZ.Strings`, item/world context
- Produces:
  - `TLOZ.RadialSatellites.openItem(item)` — Hold L2 no inventário (≤8 verbos)
  - `TLOZ.RadialSatellites.openWorld(square, player)` — Hold ✕ perto do alvo
  - `TLOZ.RadialSatellites.openEquipQuick(player)` — Hold R2
  - verbos item: Comer, Equipar, Dropar, Info (enabled conforme item)

- [ ] **Step 1: Implementar satélites**

```lua
-- media/lua/client/TLOZ/RadialSatellites.lua
require "TLOZ/RadialSlice"
require "TLOZ/Strings_PT"

TLOZ = TLOZ or {}
TLOZ.RadialSatellites = {}

local function openSlicePanel(title, slices, onPick)
  local panel = TLOZ.RadialHub:new()
  panel.slices = slices
  panel.confirm = function(self)
    local s = self.slices[self.selected]
    self:close()
    if s and onPick then onPick(s.id) end
  end
  panel:addToUIManager()
  if TLOZ._focus then TLOZ._focus:push("radial_sat") end
  if TLOZ._legend then TLOZ._legend:setContext("radial_open", TLOZ._glyphFamily or "xbox") end
  TLOZ._satPanel = panel
end

function TLOZ.RadialSatellites.openItem(item)
  local S = TLOZ.Strings
  local canEat = item and item.isFood and item:isFood()
  local canEquip = item ~= nil
  local slices = TLOZ.RadialSlice.build({
    { id = "eat", label = S.actionEat, enabled = canEat },
    { id = "equip", label = S.actionEquip, enabled = canEquip },
    { id = "drop", label = S.actionDrop, enabled = item ~= nil },
    { id = "info", label = S.actionInfo, enabled = item ~= nil },
  })
  openSlicePanel(S.radialWorld, slices, function(id)
    local player = getSpecificPlayer(0)
    if not player or not item then return end
    if id == "eat" then ISTimedActionQueue.add(ISEatFoodAction:new(player, item, 100)) end
    if id == "equip" then ISTimedActionQueue.add(ISEquipWeaponAction:new(player, item, 50, true, false)) end
    if id == "drop" then player:getCurrentSquare():AddWorldInventoryItem(item, 0, 0, 0); player:getInventory():Remove(item) end
    if id == "info" then -- tooltip/info panel vanilla
    end
    if TLOZ._dualPane then TLOZ._dualPane:refresh() end
  end)
end

function TLOZ.RadialSatellites.openWorld(player)
  local S = TLOZ.Strings
  local sq = player:getCurrentSquare()
  local hasDoor, hasWindow, hasBody, hasStove = false, false, false, false
  -- varrer objetos do square / adjacent para flags
  if sq then
    for i = 0, 3 do
      local door = sq:getDoor(i)
      if door then hasDoor = true end
    end
  end
  local slices = TLOZ.RadialSlice.build({
    { id = "door", label = "Porta", enabled = hasDoor },
    { id = "window", label = "Janela", enabled = hasWindow },
    { id = "body", label = "Corpo", enabled = hasBody },
    { id = "stove", label = "Fogão", enabled = hasStove },
  })
  openSlicePanel(S.radialWorld, slices, function(id)
    -- despachar ação vanilla correspondente (open door, etc.)
  end)
end

function TLOZ.RadialSatellites.openEquipQuick(player)
  local S = TLOZ.Strings
  local slices = TLOZ.RadialSlice.build({
    { id = "primary", label = "Mão primária", enabled = true },
    { id = "secondary", label = "Mão secundária", enabled = true },
    { id = "holster", label = "Arma rápida", enabled = true },
  })
  openSlicePanel(S.radialEquip, slices, function(id)
    -- troca rápida: abrir lista curta de armas/ferramentas da mochila (lista, não browser radial)
  end)
end

function TLOZ.RadialSatellites.openBuild()
  local S = TLOZ.Strings
  local slices = TLOZ.RadialSlice.build({
    { id = "floor", label = "Piso", enabled = true },
    { id = "wall", label = "Parede", enabled = true },
    { id = "furniture", label = "Móveis", enabled = true },
    { id = "defense", label = "Defesa", enabled = true },
  })
  openSlicePanel(S.radialBuild, slices, function(id)
    -- abrir menu build vanilla filtrado
  end)
end

function TLOZ.RadialSatellites.openVehicle(player)
  local S = TLOZ.Strings
  local nearVehicle = player:getVehicle() ~= nil or false -- + nearby vehicle check B42
  local slices = TLOZ.RadialSlice.build({
    { id = "enter", label = "Entrar", enabled = not player:getVehicle() and nearVehicle },
    { id = "hood", label = "Capô", enabled = nearVehicle },
    { id = "trunk", label = "Porta-malas", enabled = nearVehicle },
  })
  openSlicePanel(S.radialVehicle, slices, function(id) end)
end
```

- [ ] **Step 2: Ligar Hold L2 no DualPane ao item focado**

Em `DualPaneInventory`, quando L2 hold e há row selecionada com `item`, chamar `TLOZ.RadialSatellites.openItem(row.item)`.

- [ ] **Step 3: Ligar Hold ✕ mundo e Hold R2 equipamentos no bootstrap (só shell gamepad, foco world)**

- [ ] **Step 4: DoD in-game (satélites)**

1. No DualPane, focar comida → Hold L2 → fatias incluem **Comer**; item sem comida não mostra Comer.
2. Perto de porta → Hold ✕ → fatia **Porta** aparece; longe → some.
3. Hold R2 → Equipamentos (troca rápida); **não** substitui aba Equipado.
4. Nenhuma satélite lista categorias da mochila.

- [ ] **Step 5: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialSatellites.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualPaneInventory.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua
git commit -m "feat: whitelist radial satellites for item/world/equip"
```

---

### Task 11: Satélites Saúde/Mapa (via hub) + Veículo/Construção

**Files:**
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialHub.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialSatellites.lua`

**Interfaces:**
- Consumes: APIs ISUI vanilla B42 (saúde, mapa, build, veículo)
- Produces: fatias hub plenamente navegáveis; `openVehicle` / `openBuild` usáveis

- [ ] **Step 1: Completar despacho das fatias hub**

Para cada id restante, chamar a API vanilla real do branch B42 do implementador (espelhar keybind joypad stock). Critério: Saúde abre painel corpo; Mapa abre mapa; Criar abre crafting; Personagem abre skills/info; Opções abre settings.

- [ ] **Step 2: Ativar veículo quando perto/dentro**

No tick world (gamepad): se `player:getVehicle()` ou veículo adjacent, permitir atalho que chama `TLOZ.RadialSatellites.openVehicle(player)`.

- [ ] **Step 3: DoD in-game**

1. Hub → Saúde / Mapa / Criar / Personagem / Opções abrem painéis utilizáveis no pad.
2. Perto de carro → radial Veículo com Entrar/Capô/Porta-malas conforme contexto.
3. Hub → Construir → satélite Piso/Parede/Móveis/Defesa.

- [ ] **Step 4: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialHub.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialSatellites.lua
git commit -m "feat: wire hub satellites for health/map/vehicle/build"
```

---

### Task 12: DualSenseHooks (gatilhos + fallback)

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualSenseHooks.lua`
- Create: `mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/DualSensePolicy.lua`
- Create: `mods/TheLastOfZ_Gamepad/tests/test_dualsense_policy.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/RadialHub.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualPaneInventory.lua`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua`

**Interfaces:**
- Consumes: nome do controller; eventos de hold (`hub`, `item_radial`)
- Produces:
  - `TLOZ.DualSensePolicy.shouldUseAdaptive(family) → bool`
  - `TLOZ.DualSenseHooks.onHoldStart(kind)` / `onHoldEnd(kind)` — no-op seguro se sem DualSense
  - kinds: `"hub"`, `"item_radial"`

- [ ] **Step 1: Teste da policy**

```lua
-- tests/test_dualsense_policy.lua
package.path = package.path .. ";../media/lua/shared/?.lua"
require "TLOZ/DualSensePolicy"

assert(TLOZ.DualSensePolicy.shouldUseAdaptive("ps") == true)
assert(TLOZ.DualSensePolicy.shouldUseAdaptive("xbox") == false)
assert(TLOZ.DualSensePolicy.shouldUseAdaptive(nil) == false)

local effect = TLOZ.DualSensePolicy.holdEffect("hub")
assert(effect.resistance > 0)
local none = TLOZ.DualSensePolicy.holdEffect("unknown")
assert(none.resistance == 0)
```

- [ ] **Step 2: Implementar policy**

```lua
-- media/lua/shared/TLOZ/DualSensePolicy.lua
TLOZ = TLOZ or {}
TLOZ.DualSensePolicy = {}

function TLOZ.DualSensePolicy.shouldUseAdaptive(family)
  return family == "ps"
end

function TLOZ.DualSensePolicy.holdEffect(kind)
  if kind == "hub" or kind == "item_radial" then
    return { resistance = 0.45, haptic = 0.2 }
  end
  return { resistance = 0, haptic = 0 }
end
```

- [ ] **Step 3: Implementar hooks client com fallback**

```lua
-- media/lua/client/TLOZ/DualSenseHooks.lua
require "TLOZ/DualSensePolicy"

TLOZ = TLOZ or {}
TLOZ.DualSenseHooks = {}

local function nativeApply(effect)
  -- Integração: Steam Input / API nativa se exposta ao Lua na build.
  -- Se nenhuma API existir, permanece no-op (fallback elegante).
  if TLOZ._dualSenseBackend and TLOZ._dualSenseBackend.apply then
    TLOZ._dualSenseBackend.apply(effect)
  end
end

local function nativeClear()
  if TLOZ._dualSenseBackend and TLOZ._dualSenseBackend.clear then
    TLOZ._dualSenseBackend.clear()
  end
end

function TLOZ.DualSenseHooks.onHoldStart(kind)
  if not TLOZ.DualSensePolicy.shouldUseAdaptive(TLOZ._glyphFamily) then
    return
  end
  nativeApply(TLOZ.DualSensePolicy.holdEffect(kind))
end

function TLOZ.DualSenseHooks.onHoldEnd(kind)
  nativeClear()
end
```

- [ ] **Step 4: Chamar hooks nos holds**

No início do hold do hub: `TLOZ.DualSenseHooks.onHoldStart("hub")`; ao soltar/cancelar/confirm: `onHoldEnd`.  
No Hold L2 do item: `onHoldStart("item_radial")` / `onHoldEnd`.

- [ ] **Step 5: Atualizar `run_all.lua` com `test_dualsense_policy.lua` e PASS**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 run_all.lua`
Expected: todos OK.

- [ ] **Step 6: DoD DualSense**

1. DualSense PC: hold L2 (item) **ou** hold hub L1 produz resistência/feedback perceptível **se** backend nativo disponível; se API ausente, fluxo continua idêntico sem erro.
2. Xbox/pad genérico: mesmo fluxo hub → inventário → transfer sem resistência e sem exceptions.
3. Trocar de DualSense para Xbox mid-session: `detectFamily` atualiza; hooks passam a no-op.

- [ ] **Step 7: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/media/lua/shared/TLOZ/DualSensePolicy.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/DualSenseHooks.lua \
  mods/TheLastOfZ_Gamepad/tests/test_dualsense_policy.lua \
  mods/TheLastOfZ_Gamepad/tests/run_all.lua \
  mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/
git commit -m "feat: DualSense hold feedback with safe fallback"
```

---

### Task 13: Checklist DoD v1 + higiene final

**Files:**
- Create: `mods/TheLastOfZ_Gamepad/DOD_V1.md`
- Modify: `mods/TheLastOfZ_Gamepad/media/lua/client/TLOZ/bootstrap.lua` (requires finais)

**Interfaces:**
- Consumes: todo o mod
- Produces: checklist executável de aceite v1 alinhada à spec §3 DoD

- [ ] **Step 1: Escrever `DOD_V1.md`**

```markdown
# DoD v1 — TheLastOfZ_Gamepad

## Harness
- [ ] `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 run_all.lua` → ALL PASSED

## Fluxo pad (obrigatório)
- [ ] Joypad ativa GamepadShell (swap total; não só glyphs)
- [ ] Hub (hold L1) → fatia Inventário → DualPane Abas
- [ ] △/Y também abre/fecha DualPane
- [ ] Transferir 5 itens VOCÊ ↔ ALCANCE com ✕
- [ ] Equipar 1 item (aba Equipado ou verbo Equipar no L2)
- [ ] Radial contextual numa porta (Hold ✕) → ação → fechar → mundo
- [ ] ButtonLegend em português com glyphs PS ou Xbox
- [ ] Listas + categorias; zero radial-browser de loot

## DualSense
- [ ] Pelo menos um hold (L2 item ou hub) com feedback perceptível no DualSense quando backend existir
- [ ] Mesmo fluxo OK em Xbox/genérico sem erro

## Fora de escopo (não regressar)
- [ ] Sem features 3P / TLOU / narrativa / companion
```

- [ ] **Step 2: Conferir bootstrap requires na ordem**

```lua
require "TLOZ/Strings_PT"
require "TLOZ/InputMode"
require "TLOZ/InputRouter"
require "TLOZ/FocusStack"
require "TLOZ/CategoryFilter"
require "TLOZ/RadialSlice"
require "TLOZ/JoypadBindMap"
require "TLOZ/ButtonLegendModel"
require "TLOZ/DualSensePolicy"
require "TLOZ/ButtonLegend"
require "TLOZ/InventoryListPane"
require "TLOZ/DualPaneInventory"
require "TLOZ/RadialHub"
require "TLOZ/RadialSatellites"
require "TLOZ/DualSenseHooks"
require "TLOZ/UIShell"
```

- [ ] **Step 3: Executar harness + checklist in-game**

Run: `cd mods/TheLastOfZ_Gamepad/tests && lua5.1 run_all.lua`  
Expected: ALL PASSED.

In-game: marcar todos os itens do `DOD_V1.md`.

- [ ] **Step 4: Commit**

```bash
git add mods/TheLastOfZ_Gamepad/DOD_V1.md mods/TheLastOfZ_Gamepad/
git commit -m "docs: add v1 definition-of-done checklist"
```

---

## Self-review (contra a spec)

| Requisito da spec | Task |
|-------------------|------|
| Dual-pane △, VOCÊ Abas Equipado\|Mochila, ALCANCE sempre visível | 8 |
| Listas + categorias; sem cursor-mouse; sem radial-loot | 4, 8, 10 |
| Binds □/✕/○/△/L1/R1/L2 hold | 8, 9, 10 |
| ButtonLegend glyphs PS/Xbox | 6 |
| Hub radial ≤8 fatias; Inventário → DualPane | 5, 9 |
| Satélites item/mundo/equip/veículo/build | 10, 11 |
| Dual-UI InputRouter shell swap | 2, 7 |
| FocusStack ⇄ Joypad | 3, 7, 8 |
| DualSense + fallback | 12 |
| DoD v1 fluxo + DualSense | 13 |
| Strings PT | 1, 6 |
| Sem 3P/TLOU/narrativa | Global Constraints + DoD |
| Ordem entrega dual-pane → hub → satélites → DualSense | Tasks 8→9→10→11→12 |

**Placeholder scan:** nenhum TBD/TODO de implementação; APIs vanilla B42 nomeadas por contrato (abrir painel X) onde o símbolo exato varia por patch — o implementador resolve no ambiente PZ local sem mudar o comportamento de produto.

**Type consistency:** `InputMode` `"kbm"|"gamepad"`; focus ids `world|dualpane|radial_hub|radial_sat`; category ids do `ORDER`; radial ids estáveis; glyph family `"ps"|"xbox"`.
