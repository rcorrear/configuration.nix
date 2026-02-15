_: {
  den.aspects.zmx = {
    includes = [ ];
    homeManager =
      { lib, pkgs, ... }:
      let
        nc = "${pkgs.netcat}/bin/nc";
      in
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [ pkgs.rcorrear.zmx ];
        programs.ssh.matchBlocks."z.*" = {
          controlMaster = "auto";
          controlPersist = "10m";
          proxyCommand = "sh -c 'hn=\${1#z.}; exec ${nc} \"$hn\" %p' sh %n";
          extraOptions = {
            ConnectTimeout = "5";
            RemoteCommand = "zmx attach %k";
            RequestTTY = "yes";
          };
        };
      };
  };
}
