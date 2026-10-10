{
  inputs,
  lib,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      fixture = pkgs.writeShellApplication {
        name = "oathkeeper-smoke-fixture";
        runtimeInputs = [ pkgs.babashka ];
        text = ''
          exec ${pkgs.babashka}/bin/bb \
            --classpath ${self}/tests/oathkeeper/fixture/src \
            --main oathkeeper-smoke-fixture \
            "$@"
        '';
      };
    in
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        oathkeeper = pkgs.testers.runNixOSTest (
          import "${self}/tests/oathkeeper/smoke.nix" {
            inherit fixture pkgs;
            oathkeeperModule = self.nixosModules.oathkeeper;
          }
        );

        oathkeeper-microvm = import "${self}/tests/oathkeeper/microvm-smoke.nix" {
          inherit fixture pkgs;
          inherit (self.lib) mkOathkeeperMicrovm mkOathkeeperMicrovmModule;
          inherit (inputs.nixpkgs.lib) nixosSystem;
          microvmHostModule = self.nixosModules.microvm-host;
        };
      };
    };
}
