{
  description = "A basic shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.rust-overlay = {
    url = "github:oxalica/rust-overlay";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { config, ... }:
      {
        # Custom overlays for this shell
        flake.overlays.default = final: prev: { };

        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ];

        perSystem =
          {
            pkgs,
            system,
            self',
            lib,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.rust-overlay.overlays.default
                config.flake.overlays.default
                # Add overlays as needed
              ];
            };

            packages = {
              wasm = pkgs.pkgsCross.wasi32.callPackage ./package.nix { };
              default = pkgs.writeShellApplication {
                name = "wrapped-wasm";
                runtimeInputs = [ pkgs.bubblewrap ];
                text = ''
                  bwrap \
                    --unshare-all \
                    --die-with-parent \
                    --new-session \
                    --ro-bind ${lib.getExe pkgs.pkgsStatic.wasmtime} /wasmtime \
                    --ro-bind ${self'.packages.wasm}/bin/sample.wasm /target.wasm \
                    --tmpfs /tmp \
                    --chdir / \
                    --uid 65534 \
                    --gid 65534 \
                    --cap-drop all \
                    -- \
                    /wasmtime /target.wasm
                '';
              };
              debug = pkgs.writeShellApplication {
                name = "wrapped-wasm";
                runtimeInputs = [ pkgs.bubblewrap ];
                text = ''
                  bwrap \
                    --unshare-all \
                    --die-with-parent \
                    --new-session \
                    --ro-bind ${pkgs.pkgsStatic.bash}/bin /misc/bash \
                    --ro-bind ${pkgs.pkgsStatic.coreutils}/bin /misc/coreutils \
                    --ro-bind ${pkgs.pkgsStatic.tree}/bin /misc/tree \
                    --setenv PATH "/misc/bash:/misc/coreutils:/misc/tree" \
                    --tmpfs /tmp \
                    --chdir / \
                    --uid 65534 \
                    --gid 65534 \
                    --cap-drop all \
                    -- \
                    /misc/bash/bash
                '';
              };
            };

            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                rustPlatform.bindgenHook
                (rust-bin.stable.latest.default.override {
                  extensions = [
                    "rust-src"
                    "rust-analyzer"
                  ];
                  targets = [ "wasm32-wasip2" ];
                })
              ];
            };
          };
      }
    );
}
