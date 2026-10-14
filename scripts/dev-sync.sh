#!/usr/bin/env bash
# Copia mod/ pra pasta de mods do jogo como STAGING (cópia real, não symlink).
# Symlink quebra o ScriptManager do PZ — use cópia e rode de novo após cada mudança.
#
# Staging: na cópia, id ganha _Staging e nome ganha [STAGING], e incompatible=
# marca o oficial. Assim Workshop e staging podem coexistir.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
FLATPAK_ZOMBOID="$HOME/.var/app/com.valvesoftware.Steam/Zomboid"
if [ -n "${ZOMBOID_DIR:-}" ]; then :
elif [ -d "$FLATPAK_ZOMBOID" ]; then ZOMBOID_DIR="$FLATPAK_ZOMBOID"
else ZOMBOID_DIR="$HOME/Zomboid"; fi
mkdir -p "$ZOMBOID_DIR/mods"

ID="BetterGamepadAndUI"
SRC="$REPO/mod"
DEST="$ZOMBOID_DIR/mods/${ID}_Staging"
if [ -L "$DEST" ]; then rm "$DEST" && echo "symlink antigo removido"; fi
mkdir -p "$DEST"
rsync -a --delete "$SRC/" "$DEST/"
INFO="$DEST/42/mod.info"
sed -i -E -e "s/^id=.*/id=${ID}_Staging/" -e 's/^name=/name=[STAGING] /' "$INFO"
if grep -q '^incompatible=' "$INFO"; then
  sed -i "/^incompatible=/ s/\$/,\\\\$ID/" "$INFO"
else
  printf 'incompatible=\\%s\n' "$ID" >>"$INFO"
fi
echo "mod copiado como staging: $SRC -> $DEST ($(find "$DEST" -type f | wc -l) arquivos)"
