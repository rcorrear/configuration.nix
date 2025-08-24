{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  programs = config.programs;
  _1passwordEnabled = osConfig.programs._1password.enable;
  _1passwordGuiEnabled = osConfig.programs._1password-gui.enable;
in
{
  programs = lib.mkMerge [
    (lib.mkIf programs.git.enable {
      git = {
        difftastic.enable = true;
        extraConfig = {
          commit.gpgsign = true;
          gpg.format = "ssh";
          safe.directory = "${config.home.homeDirectory}/Projects/nix/flake";
          user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE";
        }
        // lib.optionalAttrs _1passwordGuiEnabled {
          "gpg \"ssh\"".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
        };
      };
    })
    (lib.mkIf programs.jujutsu.enable {
      jujutsu = {
        settings = {
          core = {
            fsmonitor = "watchman";
            watchman.register-snapshot-trigger = true;
          };
          signing = {
            behavior = "own";
            backend = "ssh";
            key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE";
          }
          // lib.optionalAttrs _1passwordGuiEnabled {
            backends.ssh.program = "${pkgs._1password-gui}/bin/op-ssh-sign";
          };
        };
      }
      // lib.optionalAttrs (programs.emacs.enable or osConfig.programs.emacs.enable) {
        ediff = true;
      };
    })
    (lib.mkIf programs.ssh.enable {
      ssh = lib.mkMerge [
        # Enable the 1Password ssh agent
        (lib.mkIf (_1passwordGuiEnabled && pkgs.stdenv.hostPlatform.isDarwin) {
          matchBlocks."*".identityAgent =
            "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
        })
        (lib.mkIf (_1passwordGuiEnabled && pkgs.stdenv.hostPlatform.isLinux) {
          matchBlocks."*".identityAgent = "${config.home.homeDirectory}/.1password/agent.sock";
        })
      ];
    })
  ];
}
