# The Last of Z — GamePad

Mod de **UI e inputs no controle** para [Project Zomboid](https://projectzomboid.com/) **Build 42**: shell gamepad próprio, inventário dual-pane (Abas), hub radial + satélites, legendas de botões e DualSense com fallback.

> English: Lua-first gamepad UI rewrite for PZ B42 — dual-pane inventory, radial hub, DualSense adaptive triggers with graceful fallback.

## Estado

| Item | Status |
|------|--------|
| Harness Lua (Tasks 1–13) | concluído |
| DoD in-game (pad / DualSense) | pendente |
| Workshop | ainda não |

Versão do mod: **0.1.0** (`mod/42/mod.info`).

## O que o mod faz

- **Dual-UI:** ao ativar o joypad, sobe o `GamepadShell` (swap total vs KB/M).
- **Inventário dual-pane (△/Y):** VOCÊ (Abas Equipado \| Mochila) + ALCANCE.
- **Hub radial (hold L1)** com fatias ≤8; satélites whitelist (item, mundo, equip, saúde, mapa, veículo, build).
- **ButtonLegend** em português com glyphs PS/Xbox.
- **DualSense:** gatilhos adaptativos / háptica quando houver backend; Xbox/genérico sem erro.

## Instalação (dev)

1. Clone este repo.
2. `scripts/dev-sync.sh` — copia `mod/` para `Zomboid/mods/TheLastOfZ_Gamepad_Staging` (defina `ZOMBOID_DIR` se não for o padrão Flatpak/`~/Zomboid`).
3. No jogo: Mods → ative **[STAGING] The Last of Z — GamePad**.
4. Reinicie o jogo após cada sync.

Para instalar “oficial” (sem staging), copie `mod/` para `Zomboid/mods/TheLastOfZ_Gamepad` (pasta com `42/` e `common/`).

## Testes

```bash
./run-tests.sh
```

Lógica pura em Lua 5.1, sem o jogo.

## Docs

- [Visão geral](docs/overview.md)
- [Design](docs/superpowers/specs/2026-10-14-ui-gamepad-zomboid-design.md)
- [Plano SDD](docs/superpowers/plans/2026-10-14-mod-gamepad-zomboid.md)
- [Sprints](docs/sprints/README.md)
- [DoD v1](mod/42/DOD_V1.md)
- [AGENTS.md](AGENTS.md) — regras pra agentes

## Layout

```
mod/42/          # payload B42 (mod.info + media/)
mod/common/      # stub B42
tests/           # harness fora do jogo
scripts/         # dev-sync
docs/sprints/    # histórico por sprint
docs/superpowers/# spec + plan
```

Estilo de projeto alinhado a [NOM — Névoa e Outro Mundo](https://github.com/WillianJohan/nevoa-e-outro-mundo) (sprints, docs, scripts), sem compartilhar conteúdo de gameplay.

## Licença

[MIT](LICENSE) — Copyright (c) 2026 Johan
