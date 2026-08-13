{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    # The actual binary is already installed elsewhere (see
    # modules/aspects/rcorrear-workstation.nix: `ghostty` on Linux and
    # `ghostty-bin`, the prebuilt macOS app, on Darwin), so don't install a
    # second copy here — this module is only used to manage
    # `~/.config/ghostty/config`.
    package = if pkgs.stdenv.isLinux then pkgs.ghostty else pkgs.ghostty-bin;

    enableFishIntegration = true;

    # home-manager's systemd (user service) integration needs the package to
    # resolve the binary path, which is impossible with `package = null;`
    # (the assertion would fail on Linux otherwise).
    systemd.enable = false;

    settings = {
      # Deal with TERM problems
      shell-integration-features = [
        "ssh-env"
        "ssh-terminfo"
        "sudo"
      ];

      # Give the text some breathing room instead of hugging the window
      # border.
      window-padding-x = 10;
      window-padding-y = 10;
    };
  };
}
