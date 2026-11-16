#!/usr/bin/env bash
# Gera o conjunto de ícones do czede a partir dos masters SVG em assets/czede/.
#
# Requer: rsvg-convert (librsvg) e magick (imagemagick) — no NixOS:
#   nix shell nixpkgs#librsvg nixpkgs#imagemagick -c scripts/build-czede-icons.sh
#
# Os nomes seguem o que scripts/lib/brand-assets.ts espera (ver BRAND_ASSET_PATHS).
set -euo pipefail

cd "$(dirname "$0")/.."
dir="assets/czede"
rounded="$dir/czede.svg"     # timbre arredondado: desktop, favicon, Windows
square="$dir/czede-square.svg" # timbre quadrado: iOS e apple-touch (máscara do sistema)

png() { # png <master> <tamanho> <arquivo>
  rsvg-convert -w "$2" -h "$2" -o "$3" "$1"
}

# Desktop e lojas de aplicativo.
png "$rounded" 1024 "$dir/czede-universal-1024.png" # Linux (.desktop, AppImage)
png "$rounded" 1024 "$dir/czede-macos-1024.png"
png "$square" 1024 "$dir/czede-ios-1024.png"

# Web / PWA / favicon.
png "$rounded" 512 "$dir/czede-web-icon-512x512.png"
png "$rounded" 192 "$dir/czede-web-icon-192x192.png"
png "$square" 180 "$dir/czede-web-apple-touch-180.png"
png "$rounded" 32 "$dir/czede-web-favicon-32x32.png"
png "$rounded" 16 "$dir/czede-web-favicon-16x16.png"

# Ícones multi-resolução.
magick "$dir/czede-web-favicon-16x16.png" "$dir/czede-web-favicon-32x32.png" \
  -define icon:auto-resize=32,16 "$dir/czede-web-favicon.ico"
magick "$dir/czede-macos-1024.png" -define icon:auto-resize=256,128,64,48,32,16 \
  "$dir/czede-windows.ico"

echo "ícones gerados em $dir:"
ls -lh "$dir" | sed 1d
