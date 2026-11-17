#!/usr/bin/env bash
# Sobe o shell Electron em modo dev. Rode de dentro do FHS:
#   nix run .#dev-desktop
#
# Não funciona direto no `nix develop`: o binário do `electron` no node_modules
# é o do upstream, que procura gtk/nss/glib em /lib — o FHS do nixpkgs resolve.
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -d node_modules ]; then
  echo "czede: sem node_modules. Rode 'nix develop' e depois 'pnpm install'." >&2
  exit 1
fi

export PATH="$PWD/node_modules/.bin:$PATH"
exec vp run dev:desktop
