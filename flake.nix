{
  description = "Dev do czede (base própria do T3 Code)";

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

      # Libs que o Electron do npm procura em /lib e que o NixOS não tem fora
      # de um FHS. Também servem o helper de segredos (libsecret/glib).
      electronRuntimeLibs =
        pkgs: with pkgs; [
          gtk3
          nss
          alsa-lib
          libgbm
          libdrm
          mesa
          libxkbcommon
          at-spi2-core
          cups
          libnotify
          libsecret
          xorg.libxshmfence
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
        ];

      buildTools =
        pkgs: with pkgs; [
          nodejs_26 # 26.13.1, o valor de engines.node
          pnpm # 12.x; ele mesmo baixa a versão exata do packageManager
          git
          # Helpers nativos que o build/dev compilam com cargo.
          rustc
          cargo
          # native/browser-secret é C e linka libsecret/glib. O gcc precisa ser o
          # do devShell: o do sistema linka contra uma glibc mais antiga que a
          # dessas libs e o `ld` falha em GLIBC_2.43.
          gcc
          gnumake
          pkg-config
          openssl
        ];
    in
    {
      devShells = forEachSystem (
        pkgs:
        let
          # Dentro do FHS o loader é o do próprio nixpkgs (glibc recente), então
          # as libs abaixo carregam; fora dele o Electron pegaria o loader do
          # nix-ld com uma glibc mais antiga e falharia em GLIBC_2.43.
          libPath = pkgs.lib.makeLibraryPath (electronRuntimeLibs pkgs);
        in
        {
          # Loop do browser/server: `nix develop` e `vp run dev`.
          default = pkgs.mkShell {
            packages = (buildTools pkgs) ++ (electronRuntimeLibs pkgs);

            shellHook = ''
              # Depois do primeiro `pnpm install`, vp/test/tsdown vivem aqui.
              export PATH="$PWD/node_modules/.bin:$PATH"
              if [ ! -d node_modules ]; then
                echo "czede: sem node_modules ainda — rode 'pnpm install' uma vez."
              fi
            '';
          };

          # Electron em dev. `.env` do buildFHSEnv não é buildável, mas
          # `nix develop .#dev-desktop` executa o runScript do FHS: aqui ele é o
          # próprio comando que sobe o app.
          dev-desktop = (pkgs.buildFHSEnv {
            name = "czede-dev-desktop";
            targetPkgs = _: (buildTools pkgs) ++ (electronRuntimeLibs pkgs);
            runScript = "${
              pkgs.writeShellScript "czede-dev-desktop-run" ''
                export LD_LIBRARY_PATH=${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
                exec ./scripts/dev-desktop.sh
              ''
            }";
          }).env;

          # Shell dentro do FHS, para debug (o LD_LIBRARY_PATH vem do profile).
          dev-desktop-shell = (pkgs.buildFHSEnv {
            name = "czede-dev-desktop-shell";
            targetPkgs = _: (buildTools pkgs) ++ (electronRuntimeLibs pkgs);
            profile = ''export LD_LIBRARY_PATH=${libPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}'';
            runScript = "bash";
          }).env;
        }
      );
    };
}
