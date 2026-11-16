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
glyph="$dir/czede.svg"         # cubo sem fundo: desktop, favicon, PWA, Windows
tile="$dir/czede-square.svg"   # timbre opaco: iOS, apple-touch e macOS

png() { # png <master> <tamanho> <arquivo>
  rsvg-convert -w "$2" -h "$2" -o "$3" "$1"
}

# Desktop e lojas de aplicativo. macOS e iOS exigem ícone opaco (o sistema
# rejeita ou pinta de preto o alpha), então esses dois saem do timbre.
png "$glyph" 1024 "$dir/czede-universal-1024.png" # Linux (.desktop, AppImage)
png "$tile" 1024 "$dir/czede-macos-1024.png"
png "$tile" 1024 "$dir/czede-ios-1024.png"

# Web / PWA / favicon.
png "$glyph" 512 "$dir/czede-web-icon-512x512.png"
png "$glyph" 192 "$dir/czede-web-icon-192x192.png"
png "$tile" 180 "$dir/czede-web-apple-touch-180.png"
png "$glyph" 32 "$dir/czede-web-favicon-32x32.png"
png "$glyph" 16 "$dir/czede-web-favicon-16x16.png"

# Ícones multi-resolução.
magick "$dir/czede-web-favicon-16x16.png" "$dir/czede-web-favicon-32x32.png" \
  -define icon:auto-resize=32,16 "$dir/czede-web-favicon.ico"
magick "$dir/czede-universal-1024.png" -define icon:auto-resize=256,128,64,48,32,16 \
  "$dir/czede-windows.ico"

echo "ícones gerados em $dir:"
ls -lh "$dir" | sed 1d
