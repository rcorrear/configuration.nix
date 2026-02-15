{
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
