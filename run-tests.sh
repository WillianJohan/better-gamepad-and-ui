#!/usr/bin/env bash
# Testa a lógica pura do mod (sem o jogo). Exit code 0 = tudo passou.
cd "$(dirname "$0")" || exit 1
cd tests || exit 1
if command -v lua5.1 >/dev/null 2>&1; then
  lua5.1 run_all.lua
elif command -v lua >/dev/null 2>&1; then
  lua run_all.lua
elif command -v luajit >/dev/null 2>&1; then
  luajit run_all.lua
else
  echo "precisa de lua5.1, lua ou luajit no PATH" >&2
  exit 127
fi
