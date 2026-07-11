{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.herdr;

  installedPlugin =
    package:
    let
      manifestPath = "${package}/herdr-plugin.toml";
      manifest = builtins.fromTOML (builtins.unsafeDiscardStringContext (builtins.readFile manifestPath));
    in
    {
      plugin_id = manifest.id;
      inherit (manifest)
        name
        version
        min_herdr_version
        platforms
        ;
      manifest_path = manifestPath;
      plugin_root = "${package}";
      enabled = true;
      build = manifest.build or [ ];
      actions = manifest.actions or [ ];
      events = manifest.events or [ ];
      panes = manifest.panes or [ ];
      link_handlers = manifest.link_handlers or [ ];
      source.kind = "local";
      warnings = [ ];
    }
    // lib.optionalAttrs (manifest ? description) {
      inherit (manifest) description;
    };
in
{
  options.programs.herdr.plugins = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
    description = ''
      Herdr plugin packages. Each package must contain a herdr-plugin.toml
      at its output root.
    '';
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."herdr/plugins.json" = lib.mkIf (cfg.plugins != [ ]) {
      text = builtins.toJSON (map installedPlugin cfg.plugins);
    };
  };
}
