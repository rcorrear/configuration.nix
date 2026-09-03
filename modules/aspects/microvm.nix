{ inputs, ... }:
{
  flake-file.inputs = {
    omni.url = "git+file:///home/rcorrear/orca/workspaces/omni/principal-authentication";
  };

  den.aspects.oathkeeper = {
    nixos = {
      imports = [ inputs.omni.nixosModules.microvm-host ];

      microvm = {
        host.enable = true;
        vms.oathkeeper.config = inputs.omni.lib.mkOathkeeperMicrovmModule {
          sessionCheckUrl = "https://wizardly-satoshi-uxq6alb7m9.projects.oryapis.com/sessions/whoami";
          upstreamUrl = "http://10.0.2.2:4100";
        };
        autostart = [ "oathkeeper" ];
      };
    };
  };
}
