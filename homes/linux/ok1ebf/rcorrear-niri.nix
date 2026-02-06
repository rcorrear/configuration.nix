{
  config,
  pkgs,
  ...
}:
{
  programs.niri = {
    settings = {
      binds = with config.lib.niri.actions; {
        "Alt+Tab" = {
          action =
            spawn "${pkgs.glib}/bin/gdbus" "call" "--session" "--dest" "io.github.isaksamsten.Niriswitcher"
              "--object-path"
              "/io/github/isaksamsten/Niriswitcher"
              "--method"
              "io.github.isaksamsten.Niriswitcher.application";
          repeat = false;
        };
        "Alt+Shift+Tab" = {
          action =
            spawn "${pkgs.glib}/bin/gdbus" "call" "--session" "--dest" "io.github.isaksamsten.Niriswitcher"
              "--object-path"
              "/io/github/isaksamsten/Niriswitcher"
              "--method"
              "io.github.isaksamsten.Niriswitcher.application";
          repeat = false;
        };
        "Alt+Grave" = {
          action = spawn "${pkgs.niriswitcher}/bin/niriswitcherctl" "show" "--workspace";
          repeat = false;
        };
        "Alt+Shift+Grave" = {
          action = spawn "${pkgs.niriswitcher}/bin/niriswitcherctl" "show" "--workspace";
          repeat = false;
        };

        "Mod+F".action.spawn = "${pkgs.fuzzel}/bin/fuzzel";
        "Mod+T".action.spawn = "${pkgs.foot}/bin/foot";

        "Mod+Shift+E".action = quit;
        "Mod+Ctrl+Shift+E".action = quit { skip-confirmation = true; };
      };
      cursor = {
        size = 18;
      };
      input.keyboard = {
        numlock = true;
        xkb = {
          layout = "us";
          model = "pc104";
          options = "caps:escape";
        };
      };
      outputs = {
        "HDMI-A-1" = {
          enable = true;
          position = {
            x = 0;
            y = 0;
          };
        };
        "DP-3" = {
          enable = true;
          focus-at-startup = true;
          position = {
            x = 1920;
            y = 0;
          };
          variable-refresh-rate = "on-demand";
        };
      };
      spawn-at-startup = [
        { command = [ "${pkgs.mako}/bin/mako" ]; }
        { command = [ "${pkgs.niriswitcher}/bin/niriswitcher" ]; }
        { command = [ "${pkgs.waybar}/bin/waybar" ]; }
      ];
    };
  };
}
