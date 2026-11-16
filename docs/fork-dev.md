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
nix develop
vp run dev             # server + web; abra a pairing URL que ele imprime
```

O renderer é servido pelo Vite com hot reload: mudança em `apps/web` aparece sem
recarregar nada. Mudança em `apps/server` pede restart do runner.

`vp run dev:desktop` sobe também o shell Electron. Ele **não** funciona direto no
NixOS: o `electron` do npm é o binário oficial do upstream (não o do nixpkgs),
que espera `libgtk-3`, `libnss3` e companhia via `/lib` — no NixOS só com
`nix-ld` + libs compatíveis, e as libs do nixpkgs-unstable exigem glibc mais nova
que a do sistema. Para usar o desktop em dev, rode dentro de um FHS:

```sh
nix shell nixpkgs#steam-run -c nix develop -c vp run dev:desktop
```

Estado do dev: `~/.t3` por padrão (`T3CODE_HOME` muda), **não** o
`~/.config/t3code-v2` do app instalado. Para começar com uma cópia dos seus
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
