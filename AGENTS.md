# AGENTS.md — regras pra qualquer agente (Cursor, Claude, etc.)

Antes de tudo, leia **[docs/overview.md](docs/overview.md)** e o índice de **[docs/sprints/](docs/sprints/README.md)**.

## Regras que não se negociam

- **Escopo do produto:** UI/input no gamepad (shell, dual-pane, radiais whitelist, DualSense). Sem câmera 3P, narrativa TLOU, companion ou quests.
- **Lua roda em Kahlua (subset de Lua 5.1):** sem `next()`, `//`, `goto` nem operadores de bit; use `unpack`, nunca `table.unpack`.
- **Lógica pura em `media/lua/shared/`**, testada fora do jogo com `./run-tests.sh`. UI ISUI em `client/`.
- **Strings de UI do mod em português** (`Strings_PT.lua` / Translate quando houver). Identificadores de código em inglês.
- **Dual-UI obrigatório:** gamepad = shell próprio (swap total); sem painel KBM “meio adaptado”.
- **DualSense** com fallback obrigatório em Xbox/pad genérico.
- Comentários e docs em português BR com acento.
- Commits pequenos, mensagem em português.

## Comandos

```bash
./run-tests.sh            # harness Lua (lógica pura)
scripts/dev-sync.sh       # COPIA mod/ pra pasta de mods do jogo como STAGING
```

- **Jogo:** Steam (Flatpak comum) em `~/Zomboid` ou `ZOMBOID_DIR`.
- **Log:** `console.txt` na pasta de dados do Zomboid.

## Hot-reload no jogo

Após `scripts/dev-sync.sh`, no **console de debug** Lua do PZ:

```lua
BGUI_rebootstrap()   -- recuperação se reload sumiu / tabela half-dead
BGUI_status()        -- global resiliente (equivale a BGUI.status)
BGUI_reload()        -- global resiliente; se reload nil, cai pra rebootstrap
BGUI.status()        -- mode, shell, focus, dualPane, bootOk
BGUI.reload()        -- hot-reload normal (preserva helpers se bootstrap falhar)
```

Preferir **`BGUI_status()` / `BGUI_reload()` / `BGUI_rebootstrap()`** no console — não morrem se a tabela `BGUI` ficar half-dead. `BGUI.reload` / `BGUI.status` são redefinidos no início do bootstrap (`Debug.lua`).

- **Basta reload/rebootstrap:** mudanças de lógica `shared/` / `client/` Lua na maioria dos casos.
- **Ainda precisa menu → Load (ou restart):** alterações pesadas em classes ISUI (`derive`), `mod.info`, assets novos, ou se o console mostrar `[BGUI] bootstrap failed`.

## Desenvolvimento x lançado

- **`main`** = o que está (ou vai estar) no Workshop / release.
- Trabalho de sprint em branch `sprint/00NN-slug`; docs em `docs/sprints/sprint-00NN-slug/`.
- Staging no jogo: `scripts/dev-sync.sh` copia com id `_Staging` e nome `[STAGING]`.

## Fluxo de sprint

1. Branch `sprint/00NN-slug` saindo de `main` (ou `staging`, se existir).
2. Plano e notas em `docs/sprints/sprint-00NN-slug/`.
3. TDD na lógica pura; `./run-tests.sh` verde.
4. Review no final da entrega; merge; `scripts/dev-sync.sh` pra playtest.
