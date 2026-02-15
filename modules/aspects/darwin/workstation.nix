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
          keyboard = {
            enableKeyMapping = true;
            remapCapsLockToEscape = true;
          };
        };
      };
  };
}
