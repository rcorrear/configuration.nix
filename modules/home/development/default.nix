{
  lib,
  config,
  osConfig,
  pkgs,
  ...
}:
let
  _1PasswordGuiEnabled = osConfig.programs._1password-gui.enable;
  _1PasswordSshSock =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${config.home.homeDirectory}/.1password/agent.sock";
  op-ssh-sign =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
      "${pkgs._1password-gui}/bin/op-ssh-sign";
in
{
  home = {
    sessionVariables = {
      SSH_AUTH_SOCK = _1PasswordSshSock;
    };
  };

  programs = lib.mkMerge [
    (lib.mkIf config.programs.git.enable {
      git = {
        difftastic.enable = true;
      }
      // lib.optionalAttrs _1PasswordGuiEnabled {
        extraConfig = {
          commit.gpgsign = true;
          "gpg \"ssh\"".program = op-ssh-sign;
          gpg.format = "ssh";
        };
      };
    })
    (lib.mkIf config.programs.jujutsu.enable {
      jujutsu = {
        settings = {
          fix.tools = {
            nixfmt = {
              command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
              patterns = [ "glob:'**/*.nix'" ];
            };
          };
          fsmonitor = {
            backend = "watchman";
            watchman.register-snapshot-trigger = true;
          };
          ui = {
            default-command = "status";
            diff.formatter = "${pkgs.difftastic}/bin/difft --color=always $left $right";
          }
          // lib.optionalAttrs _1PasswordGuiEnabled {
            backends.ssh.program = op-ssh-sign;
            git.sign-on-push = true;
            signing = {
              behavior = "own";
              backend = "ssh";
            };
          };
        };
      }
      // lib.optionalAttrs (config.programs.emacs.enable or osConfig.programs.emacs.enable) {
        ediff = true;
      };
    })
  ];
}
