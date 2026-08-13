{
  inputs,
  pkgs,
  ...
}:
let
  zmxFlake = inputs.zmx;
in
{
  flake-file.inputs.zmx = {
    url = "github:neurosnap/zmx/v0.4.2";
  };

  config = {
    home.packages = [
      zmxFlake.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    programs.starship.settings = {
      format = "\\${env_var.ZMX_SESSION}\\\n...\n";

      env_var.ZMX_SESSION = {
        symbol = " ";
        format = "[$symbol$env_value]($style) ";
        description = "zmx session name";
        style = "bold magenta";
      };
    };

    programs.ssh.settings."z.*" = {
      ControlMaster = "auto";
      ControlPersist = "10m";
      HostName = "%h";
      ProxyCommand = "sh -c 'hn=\${1#z.}; exec nc \"$hn\" %p' sh %n";
      ConnectTimeout = "5";
      RemoteCommand = "zmx attach %k";
      RequestTTY = "yes";
    };
  };
}
