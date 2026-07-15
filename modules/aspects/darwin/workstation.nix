{ den, ... }:
{
  den.aspects.darwin-workstation = {
    includes = [
      den.aspects.darwin-base
    ];

    darwin =
      { pkgs, ... }:
      {
        environment = {
          extraOutputsToInstall = [
            "doc"
            "info"
            "devdoc"
          ];
          shells = [ pkgs.fish ];
          systemPackages = [ pkgs.neovim ];
        };

        homebrew = {
          enable = true;
          casks = [
            "ghostty"
            "raycast"
          ];
          onActivation.cleanup = "zap";
        };

        networking = {
          search = [
            "home.arpa"
            "wifi.home.arpa"
          ];
        };

        security.pam.services.sudo_local.touchIdAuth = true;

        system = {
          # `true` (natural/swipe-direction scrolling) is macOS's own default,
          # so this is set to `false` here for traditional scrolling (scroll
          # down moves content down), which actually changes it from the
          # default. You need to log out and back in (or restart) for
          # already-running apps to pick up the change
          defaults.NSGlobalDomain."com.apple.swipescrolldirection" = false;

          keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = true;
          };
        };
      };
  };
}
