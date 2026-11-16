#!/usr/bin/env bash
# Tag -> CI -> release -> hash para o pacote NixOS deste fork.
#
# Uso:
#   scripts/release-fork.sh            # proxima -fork.<n> sobre a base atual
#   scripts/release-fork.sh 0.2.0      # nova base (depois de mergear upstream)
#   scripts/release-fork.sh --dry-run  # so mostra o que faria
#
# Requer: git limpo em main, gh autenticado, nix (store prefetch-file).
set -euo pipefail

readonly REPO="lafco/czede"
readonly WORKFLOW="release-appimage.yml"
readonly NIX_FILE="pkgs/t3code.nix"

die() {
  printf 'erro: %s\n' "$*" >&2
  exit 1
}

cd "$(git rev-parse --show-toplevel)"

dry_run=false
base=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    -h | --help)
      sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) base="$arg" ;;
  esac
done

# --- pre-condicoes ---------------------------------------------------------
[[ "$(git rev-parse --abbrev-ref HEAD)" == "main" ]] || die "precisa estar em main"
[[ -z "$(git status --porcelain)" ]] || die "arvore suja; commite ou stashe antes"
git fetch -q origin main --tags
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]] ||
  die "HEAD difere de origin/main; faca push antes"

command -v gh >/dev/null || die "gh nao encontrado"
command -v nix >/dev/null || die "nix nao encontrado"

# --- proxima versao --------------------------------------------------------
# Tags de release do fork: v<base>-fork.<n>. A base mais recente e a do maior
# tag (a base muda quando mergeamos um upstream novo).
latest_tag="$(git tag -l 'v*-fork.*' | sort -V | tail -1)"
[[ -n "$latest_tag" ]] || die "nenhum tag v*-fork.* encontrado"

latest_base="$(sed -E 's/^v(.*)-fork\.[0-9]+$/\1/' <<<"$latest_tag")"
latest_n="$(sed -E 's/^.*-fork\.([0-9]+)$/\1/' <<<"$latest_tag")"

if [[ -z "$base" ]]; then
  base="$latest_base"
  n=$((latest_n + 1))
elif [[ "$base" == "$latest_base" ]]; then
  n=$((latest_n + 1))
else
  n=1
fi

version="${base}-fork.${n}"
tag="v${version}"
asset="czede-${version}-x86_64.AppImage"
url="https://github.com/${REPO}/releases/download/${tag}/${asset}"

printf 'ultimo tag : %s\n' "$latest_tag"
printf 'novo tag   : %s\n' "$tag"
printf 'asset      : %s\n' "$asset"

if $dry_run; then
  printf '\n--dry-run: nada foi criado nem publicado.\n'
  exit 0
fi

# --- tag + build -----------------------------------------------------------
git tag -a "$tag" -m "Build próprio do T3 Code ${version} (fork ${n})"
git push origin "$tag"

printf '\naguardando o workflow %s para %s...\n' "$WORKFLOW" "$tag"
sleep 15
run_id="$(gh run list --repo "$REPO" --workflow "$WORKFLOW" --limit 5 \
  --json databaseId,headBranch \
  --jq "[.[] | select(.headBranch == \"$tag\")][0].databaseId")"
[[ -n "$run_id" ]] || die "nenhum run encontrado para $tag"

if ! gh run watch "$run_id" --repo "$REPO" --exit-status; then
  printf '\nbuild falhou: https://github.com/%s/actions/runs/%s\n' "$REPO" "$run_id" >&2
  printf 'corrija, e rode de novo: o proximo n sera %s\n' "$((n + 1))" >&2
  exit 1
fi

gh release view "$tag" --repo "$REPO" --json assets --jq '.assets[].name' | grep -qx "$asset" ||
  die "release nao tem $asset"

# --- hash + bloco para o nixos --------------------------------------------
prefetch_json="$(nix store prefetch-file --json --hash-type sha256 "$url")"
hash="$(jq -r .hash <<<"$prefetch_json")"

cat <<EOF

release: https://github.com/${REPO}/releases/tag/${tag}
sha256 : ${hash}

cole em ~/nixos/${NIX_FILE}:
    version = "${version}";
    src = fetchurl {
      url = "https://github.com/${REPO}/releases/download/v\${version}/czede-\${version}-x86_64.AppImage";
      hash = "${hash}";
    };

e valide:
    nix build --impure --expr 'let f = builtins.getFlake "/home/lafco/nixos";
      pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.callPackage /home/lafco/nixos/${NIX_FILE} { }'
EOF
