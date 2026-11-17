# Ambiente de dev deste fork

`flake.nix` na raiz dá o shell: node 26.13.1 (o valor de `engines.node`), pnpm,
Rust para `native/*`, gcc + libsecret para `native/browser-secret`.

## Primeira vez

```sh
cd ~/repos/czede
nix develop            # node 26.13.1, pnpm 12.14.0, rustc, gcc, pkg-config
pnpm install           # ~2 min, ~1 GB em node_modules; uma vez só
```

`pnpm` se auto-ajusta para 12.14.0 (`packageManager` no `package.json`), então o
pnpm do nixpkgs serve. Os binários `vp`, `tsdown` e os runners de teste entram no
PATH pelo `shellHook` (`node_modules/.bin`).

## Loop do dia a dia

```sh
cd ~/repos/czede
nix develop
vp run dev             # server + web; abra a pairing URL que ele imprime
```

O renderer é servido pelo Vite com hot reload: mudança em `apps/web` aparece sem
recarregar nada. Mudança em `apps/server` pede restart do runner. Esse é o loop
rápido, e nada dele passa por nix, CI ou release.

Também dá para subir só o server (`vp run dev:server`) ou só o web
(`vp run dev:web`).

## Shell Electron (desktop) em dev

`vp run dev:desktop` precisa do shell do Electron, que é o binário do npm:
ele espera uma FHS (`/lib`, `ld.so`) e, no NixOS, só acha `gtk`/`nss`/`glib`
coerentes dentro de um FHS do próprio nixpkgs. Por isso existe um shell que
monta esse FHS:

```sh
nix develop .#dev-desktop         # sobe server + web + Electron dentro do FHS
nix develop .#dev-desktop-shell   # shell dentro do FHS, para debugar
./scripts/dev-desktop.sh          # (dentro do shell acima) sobe o desktop
```

Estado do dev: `~/.t3` por padrão (`T3CODE_HOME` muda), **não** o
`~/.config/czede` do app instalado. Para começar com uma cópia dos seus
projetos e threads paradas: `vp run migrate-dev-db`.

## Verificação antes de pushar

```sh
vp run check:changed   # formato, lint, knip, typecheck e testes do que mudou
```

## Detalhe de sandbox

Se o build do `native/browser-secret` falhar com `undefined reference to
free_sized@GLIBC_2.43`, você está com `NIX_CFLAGS_LINK`/`NIX_LDFLAGS` herdados
apontando `-L/usr/lib` (acontece ao rodar o dev de dentro do sandbox FHS do app
T3 Code). Fora dele, num terminal normal, não acontece; se acontecer, `unset
NIX_CFLAGS_LINK NIX_LDFLAGS`.

## Release

O dev não publica nada. Para virar binário instalado, ver
[docs/fork-release.md](./fork-release.md): tag `v<versao>-fork.<n>` ->
`scripts/release-fork.sh` -> bump em `~/nixos/pkgs/t3code.nix`.
