# Git and Jujutsu SSH-based commit signing configuration
#
# This module configures both Git and Jujutsu to sign commits using SSH keys
# via 1Password's SSH agent. The SSH signing program path is automatically
# selected based on the platform (Darwin vs Linux).
#
# Signing key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE
#
{
  config,
  lib,
  pkgs,
  ...
}:
let
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAs0HUuftvwkh3IC+ilQ7mCjTBgXGquy0+VXoQDNPadE";

  # Platform-specific SSH signing program path
  sshSignProgram =
    if pkgs.stdenv.isDarwin then
      "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
      "${pkgs._1password-gui}/bin/op-ssh-sign";
in
{
  options.den.sshAgentSocket = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/.1password/agent.sock";
    description = "Path to the SSH agent socket used for Git/Jujutsu signing.";
  };

  config = {
    home.sessionVariables.SSH_AUTH_SOCK = lib.mkDefault config.den.sshAgentSocket;

    programs.git.settings = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg."ssh".program = sshSignProgram;
      user.signingkey = signingKey;
    };

    programs.jujutsu.settings.signing = {
      behavior = "own";
      backend = "ssh";
      backends.ssh.program = sshSignProgram;
      key = signingKey;
    };
  };
}
