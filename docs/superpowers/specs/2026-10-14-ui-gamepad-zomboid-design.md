# Design: Mod GamePad / Inputs — Project Zomboid

**Project:** The Last of Z  
**Data:** 2026-10-14  
**Status:** design do mod de gamepad (revisão pós-higiene de contexto)  
**Produto:** mod Lua-first que **reescreve a experiência de input/UI no controle**, com suporte forte a **DualSense (PS5)**.

Este Project **não** trata de câmera 3ª pessoa, TLOU, narrativa, companion, quests nem arte AAA. Qualquer menção antiga a isso está arquivada e fora do trabalho ativo.

---

## 1. Inventário

**Abertura:** △ / Y → dual-pane. Mesma tela via fatia Inventário do hub radial.

### Esquerda — VOCÊ
- Abas: **Equipado** | **Mochila** (L1/R1 com foco à esquerda)
- **Equipado:** lista curta — mãos, roupa, luz, slots de corpo (ordem estável)
- **Mochila:** lista longa por categorias (Armas, Munição, Roupas, Comida, Água, Med, Recipientes, Ferramentas, Misc…)
- Header: capacidade kg + estado
- Estilo: **C Tactical Diegetic** (listas, familiar pra quem já joga PZ)

### Direita — ALCANCE (sempre visível)
- Container/tile atual + distância
- L1/R1 com foco à direita = ciclar alvo nearby
- Mesma gramática lista + categorias

### Navegação

| Input | Ação |
|--------|------|
| Stick / D-pad ↑↓ | Linha na lista |
| □ | Trocar lado (Você ↔ Alcance) |
| ✕ | Transferir / usar contextual |
| ○ | Voltar / fechar overlay |
| △ | Fechar dual-pane |
| Hold L2 | Radial ações do **item focado** (≤8 verbos) |

### Regras
- Sem cursor-como-mouse
- Sem radial para navegar loot/categorias
- Legend no rodapé (glyphs PS / Xbox conforme controle)
- Modo gamepad = shell próprio (swap total vs KB/M)

---

## 2. Hub radial + satélites

Radial = casca de navegação / verbos. **Não** browser de loot.

### Hub principal (hold L1 ou botão mapeável)
Hold abre · stick escolhe · ✕ confirma · ○ cancela.

Fatias (≤8):
1. Inventário → dual-pane Abas  
2. Saúde → painel corpo PZ + ações rápidas  
3. Mapa → mapa + marcadores  
4. Criar / Craft → crafting  
5. Construir → satélite build ou menu  
6. Personagem → skills / traits / info  
7. Opções → settings do mod / jogo  

### Satélites (whitelist)

| Radial | Quando | Conteúdo |
|--------|--------|----------|
| Equipamentos | Hold R2 / atalho | Troca rápida mãos/armas/ferramentas |
| Contextual mundo | Hold ✕ perto do alvo | Porta, janela, corpo, fogão… |
| Veículo | Perto/dentro do carro | Entrar, capô, porta-malas… |
| Construção | Via hub / hold build | Piso, parede, móveis, defesa… |
| Item focado | Hold L2 no inventário | Comer, Equipar, Dropar, Info… |

### Regras
- Máx. 8 fatias; vazias somem  
- Parâmetro extra → verbo no radial + modal/lista curta  
- Proibido: radial como browser de mochila/categorias/saque  
- KB/M: mesmos hubs (atalhos estilo conceito GPT)

### Ordem de entrega
1. Dual-pane inventário  
2. Hub + fatia Inventário  
3. Radial item focado + contextual mundo  
4. Equipamentos / Saúde / Mapa  
5. Veículo + Construção  
6. DualSense (gatilhos) em holds/ações elegíveis  

**Ref:** `docs/refs/project-zomboid-gamepad-ui-concept-gpt.pdf` · `docs/refs/leitura-conceito-gpt-radiais.md`

---

## 3. Shell, DualSense, limites do mod

### Dual-UI
- Shells: **KB/M** (legado PZ) e **Gamepad** (nosso)
- Detecção: Joypad activate / primeiro input decisivo
- Enter gamepad → sobe GamepadShell; exit → restaura KB/M
- No pad: sem painel KBM “meio adaptado”

### Stack
```
InputRouter (kbm|gamepad)
  → UIShell
       → KbmShell | GamepadShell
            DualPaneInventory (Abas)
            RadialHub + satélites
            ButtonLegend
            DualSenseHooks (opcional)
            FocusStack ⇄ JoypadData
```
Lua-first (`ISUI` + Joypad). Integração DualSense conforme APIs/modding disponíveis (Steam Input / native); sempre degradar com elegância.

### DualSense (importante — PS5 / DualSense no PC)
- Gatilhos adaptativos L2/R2 onde fizer sentido (holds de radial, ações com “peso”, etc.)
- Háptica leve alinhada aos mesmos eventos, se viável
- **Fallback obrigatório:** Xbox / pad genérico = mesmos binds, sem resistência
- Faz parte do produto do mod; pode iterar depois do dual-pane estável, mas não é “nice-to-have esquecido”

### Adiado dentro do próprio mod (não é outro projeto)
- Rewrite profundo de combate no pad (aim/shove/stance) — só o mínimo no v1 pra não conflitar com radiais; aprofundar em iteração seguinte  
- Polish de todos os painéis vanilla (Vehicle Mechanics, etc.) além do inventário/hub  

### DoD v1 do mod
Só no pad: hub → inventário → transferir 5 itens → equipar → radial contextual numa porta → fechar → mundo.  
Em DualSense: pelo menos um hold (L2 ou hub) com feedback de gatilho perceptível + mesmo fluxo ok sem DualSense.

---

## Referências ativas
- `docs/estudo-ui-gamepad-zomboid.md`
- `docs/mocks-ui-gamepad-abc.md` · `docs/mocks-layout-equipado-carregado.md`
- `media/ui-gamepad-mocks/layout-2-abas.png`
- `internal/brainstorm-inv-*.md`
