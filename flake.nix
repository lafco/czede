{
  description = "Dev shell do czede (base própria do T3 Code)";

  # Pina o unstable porque o repo exige node 26.13.1 (engines.node) e o estável
  # do nixpkgs ainda não tem essa série.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forEachSystem (
        pkgs: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs_26 # 26.13.1, o valor de engines.node
              pnpm # 12.x; ele mesmo baixa a versão exata do packageManager
              git
              # Helpers nativos que o build/dev compilam com cargo.
              rustc
              cargo
              # native/browser-secret é C e linka libsecret/glib. O gcc precisa ser
              # o do devShell: o do sistema linka contra uma glibc mais antiga que
              # a dessas libs e o `ld` falha em GLIBC_2.43.
              gcc
              gnumake
              pkg-config
              # Helper de segredos do navegador no Linux.
              libsecret
              openssl
            ];

            shellHook = ''
              # Depois do primeiro `pnpm install`, vp/test/tsdown vivem aqui.
              export PATH="$PWD/node_modules/.bin:$PATH"
              if [ ! -d node_modules ]; then
                echo "czede: sem node_modules ainda — rode 'pnpm install' uma vez."
              fi
            '';
          };
        }
      );
    };
}
