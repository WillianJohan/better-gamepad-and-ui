# Better Gamepad and UI

Mod Lua-first para **Project Zomboid Build 42** que troca a experiência de UI/input no controle: shell gamepad próprio, inventário dual-pane (Abas), hub radial com satélites whitelist, ButtonLegend e DualSense com fallback.

## Estado (2026-10-14)

- **Código v0.1.0** — Tasks 1–13 do plano SDD implementadas; harness Lua verde.
- **DoD in-game** — ainda aberto (fluxo pad + DualSense no cliente PZ).
- **Fora de escopo:** câmera 3P, narrativa TLOU, companion, quests, arte AAA.

## Docs

| Doc | Conteúdo |
|-----|----------|
| [spec](superpowers/specs/2026-10-14-ui-gamepad-zomboid-design.md) | Design do produto |
| [plan](superpowers/plans/2026-10-14-mod-gamepad-zomboid.md) | Plano SDD Tasks 1–13 |
| [sprints](sprints/README.md) | Histórico de sprints (espelho do plano) |
| [DoD v1](../mod/42/DOD_V1.md) | Checklist de aceite no jogo |

## Layout do repo

Espelha o estilo de [NOM](https://github.com/WillianJohan/nevoa-e-outro-mundo): `mod/` (payload B42), `tests/` + `run-tests.sh`, `docs/sprints/`, `scripts/`, `AGENTS.md`.
