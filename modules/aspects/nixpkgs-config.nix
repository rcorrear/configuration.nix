{
  inputs,
  lib,
  config,
  ...
}:
let
  rcorrearOverlay =
    final: prev:
    let
      herdrPluginMeta = {
        homepage = "https://herdr.dev/plugins/";
        platforms = final.lib.platforms.linux ++ final.lib.platforms.darwin;
      };

      herdrPlugins = {
        jj-workspace = final.rustPlatform.buildRustPackage rec {
          pname = "herdr-plugin-jj-workspace";
          version = "0.1.0";

          src = final.fetchFromGitHub {
            owner = "NathanFlurry";
            repo = "herdr-plugin-jj-workspace";
            rev = "a9f1d3bcdaa2354e336a5173da85cbe4970c0f2e";
            hash = "sha256-xspdQfcwTEdUwZ0nWAfrdvz5IBVNVyMkmpmpzkUl0LE=";
          };

          cargoHash = "sha256-DhRLJs6ikN1q6TY+D7ghffvWdwCVMhw9YJL4D7TARt4=";

          installPhase = ''
            runHook preInstall

            mkdir -p $out/target/release
            cp herdr-plugin.toml README.md LICENSE $out/
            cp target/*/release/jj-workspace $out/target/release/

            runHook postInstall
          '';

          meta = herdrPluginMeta // {
            description = "Create and remove Jujutsu workspaces as Herdr workspaces or tabs";
            homepage = "https://github.com/NathanFlurry/herdr-plugin-jj-workspace";
            license = final.lib.licenses.mit;
          };
        };

        worktree-setup = final.buildNpmPackage rec {
          pname = "herdr-worktree-setup";
          version = "0.1.0";

          src = final.fetchFromGitHub {
            owner = "tdi";
            repo = "herdr-worktree-setup";
            rev = "cf01280853511e3dd52fc88207641bf250e6b1d0";
            hash = "sha256-it3ZLMkLHitLqqFvMOKfpnjNfrNx5iR8Lwgg6+EAaSk=";
          };

          npmDepsHash = "sha256-8qkB12gFgppNZLnnUCN2uAhagzuHIdEeX/ymejZZaFI=";
          dontNpmBuild = true;

          postPatch = ''
            substituteInPlace herdr-plugin.toml \
              --replace-fail 'command = ["node", "src/setup.js"]' \
              'command = ["${final.lib.getExe final.nodejs}", "src/setup.js"]'
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp -R herdr-plugin.toml README.md config.example.toml package.json package-lock.json src node_modules $out/

            runHook postInstall
          '';

          meta = herdrPluginMeta // {
            description = "Run per-project setup steps when a Herdr worktree is created";
            homepage = "https://github.com/tdi/herdr-worktree-setup";
            license = final.lib.licenses.mit;
          };
        };
      };
    in
    {
      rcorrear = {
        cider-3 = final.callPackage ../../packages/cider-3 { };
        exiled-exchange2 = final.callPackage ../../packages/exiled-exchange2 { };
        headroom = final.callPackage ../../packages/headroom { };
        inherit herdrPlugins;
        jj-waltz = final.callPackage ../../packages/jj-waltz { };
        rtk = final.callPackage ../../packages/rtk { };
        zmx = final.callPackage ../../packages/zmx { };
      };

      # Work around an upstream OpenLDAP 2.6.13 syncrepl test failure that
      # currently blocks Lutris through its transitive dependency chain.
      openldap = prev.openldap.overrideAttrs (_: {
        doCheck = false;
      });
    };

  overlaysFor =
    system:
    [ rcorrearOverlay ]
    ++ lib.optionals (lib.hasInfix "linux" system) [
      inputs.niri-flake.overlays.niri
    ];

  nixpkgsConfigUnfree = {
    allowUnfree = true;
  };
in
{
  flake-file.inputs = {
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.nixpkgs-config = {
    includes = [ ];

    nixos.nixpkgs = {
      config = nixpkgsConfigUnfree;
      overlays = overlaysFor (config._module.args.system or "");
    };

    homeManager.nixpkgs = {
      config = nixpkgsConfigUnfree;
      overlays = overlaysFor (config._module.args.system or "");
    };

    darwin.nixpkgs = {
      config = nixpkgsConfigUnfree;
      overlays = overlaysFor (config._module.args.system or "");
    };
  };
}
