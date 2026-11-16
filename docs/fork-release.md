# Release deste fork (Linux AppImage)

Este repositório é uma base própria derivada de `pingdotgg/t3code`. O release
oficial do upstream não existe aqui: `release.yml`/`release-desktop.yml` ficaram
fora e os runners deles são Blacksmith da org `pingdotgg`. Quem produz o binário
que o NixOS consome é `.github/workflows/release-appimage.yml`.

## O ciclo completo

1. mudança commitada e pushada em `main`;
2. tag nova `v<versao>-fork.<n>` e push — isso dispara o workflow;
3. workflow builda em `ubuntu-24.04` e publica no release do tag:
   `T3-Code-<versao>-x86_64.AppImage` + `SHA256SUMS`;
4. no repo NixOS (`~/nixos`), `pkgs/t3code.nix` recebe `version` e `hash` novos.

O passo 2 ao 4 é o que `scripts/release-fork.sh` faz (menos editar o arquivo
nix, que ele imprime pronto):

```sh
scripts/release-fork.sh            # proxima -fork.<n> sobre a base atual
scripts/release-fork.sh 0.2.0      # nova base, quando o upstream for atualizado
```

Depois do script, cole o bloco que ele imprime em `~/nixos/pkgs/t3code.nix` e
valide com:

```sh
nix build --impure --expr 'let f = builtins.getFlake "/home/lafco/nixos";
  pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
  in pkgs.callPackage /home/lafco/nixos/pkgs/t3code.nix { }'
```

## Regras

- Tag sempre com sufixo `-fork.<n>`. Os tags do upstream continuam existindo no
  remote `upstream`; `v0.1.9` puro já está usado.
- Nunca reescrever um tag já publicado: `n` sempre incrementa. O asset leva o
  nome da versão, então duas builds do mesmo tag geram URLs iguais com bytes
  diferentes.
- `~/.repos` não existe neste repo. O CI do upstream excluía esse diretório do
  checkout; aqui ele foi removido de vez.
- O config público do T3 Connect (Clerk publishable key, template JWT, client id
  do OAuth da CLI, URL do relay) vem do `.env.example` dentro do workflow. São
  identificadores públicos, os mesmos que os builds oficiais embutem. Sem eles o
  app sai sem T3 Connect.
- Sem assinatura: Linux não assina (o upstream só assina macOS e Windows). Por
  isso não há secret nenhum configurado no repo.
- O `pkgs/t3code.nix` desliga o auto-update (`T3CODE_DISABLE_AUTO_UPDATE=1`):
  atualizar versão é bump no NixOS, não é o app se atualizando. O
  `app-update.yml` dentro do pacote aponta para `lafco/czede` de qualquer forma.

## Quando o upstream publicar versão nova

```sh
git fetch upstream --tags
git merge upstream/main          # ou cherry-pick do que interessa
```

Depois disso o tag do release vira `v<versao-nova>-fork.1`:
`scripts/release-fork.sh <versao-nova>`.

## O que o workflow faz

Passos em `.github/workflows/release-appimage.yml`:

- `Checkout` com `fetch-depth: 0` (o packager resolve versão/commit pelo git);
- `Load public config` a partir do `.env.example`;
- `./.github/actions/setup-ci-deps` (composite herdado do upstream: instala
  Vite+ e `vp install` com filtros);
- libs do desktop Linux (`libsecret-1-dev`, gtk3, nss, asound, gbm);
- `dtolnay/rust-toolchain` para `native/resource-monitor` e os capture helpers;
- `vp run dist:desktop:artifact --platform linux --target AppImage --arch x64
  --build-version <versao>`, que alinha os manifests, roda `build:desktop` e
  empacota;
- rename para `T3-Code-<versao>-x86_64.AppImage` + `SHA256SUMS` (o packager
  sozinho solta `T3-Code-x86_64.AppImage`, sem versão);
- `gh release create` (ou `upload --clobber` num rerun).
