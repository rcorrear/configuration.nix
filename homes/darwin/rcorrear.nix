{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../all/rcorrear.nix
  ];

  home = {
    packages = [
      pkgs.discord
    ];

    sessionVariables = {
      NH_FLAKE = "${config.home.homeDirectory}/Projects/nix/configuration.nix";
      SSH_AUTH_SOCK = config.den.sshAgentSocket;
    };
  };

  programs = {
    fish = {
      enable = true;
    };

    ssh = {
      enable = true;
    };

    zsh = {
      enable = true;
      loginExtra = ''
        if [[ $(/bin/ps -o command= -p "$PPID" | /usr/bin/awk '{print $1}') != 'fish' ]]
        then
            exec ${pkgs.fish}/bin/fish -l
        fi
      '';
    };
  };
}
