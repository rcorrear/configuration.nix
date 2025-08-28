{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.archetypes.programs.emacs;
in
{
  options.archetypes.programs.emacs = {
    enable = mkEnableOption "Whether to enable our emacs configuration.";
  };

  config = mkIf cfg.enable {
    home = {
      sessionPath = [
        "${config.xdg.configHome}/emacs/bin"
      ];
    };

    programs = {
      emacs = {
        enable = true;
        extraPackages = epkgs: [
          epkgs.emacsql
          epkgs.vterm
        ];
      };
    };

    services = {
      emacs = {
        client.enable = true;
        defaultEditor = true;
        enable = true;
        startWithUserSession = true;
      };
    };
  };
}
