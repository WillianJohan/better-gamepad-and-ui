# Sprint 0002 — InputRouter (modo kbm|gamepad)

| Campo | Valor |
|-------|-------|
| Status | `concluída` |
| Branch | `sprint/0002-input-router` |
| Origem | Task 2 do [plano SDD](../../superpowers/plans/2026-10-14-mod-gamepad-zomboid.md) |
| Spec | [design](../../superpowers/specs/2026-10-14-ui-gamepad-zomboid-design.md) |

## Objetivo

Detecta primeiro input decisivo e emite enter/exit de modo.

## Critérios de aceite

- [x] Código e testes da task no harness Lua
- [x] `./run-tests.sh` cobre o módulo (ou o suite completo) e passa
- [ ] Validação in-game no cliente PZ (lote DoD v1 — ver sprint 0013 / `mod/42/DOD_V1.md`)

## Checkpoints

- **2026-10-14** — Implementado no ciclo SDD Tasks 1–13; tip interno `8fe9396` antes da publicação do repo.

## Aprendizados

- Layout público alinhado ao estilo NOM: payload em `mod/42/`, testes na raiz, docs em `docs/sprints/`.
