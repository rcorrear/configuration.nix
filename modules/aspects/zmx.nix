_: {
  den.aspects.zmx = {
    includes = [ ];
    homeManager =
      { pkgs, ... }:
      let
        nc = "${pkgs.netcat}/bin/nc";
        zmxPkg = pkgs.rcorrear.zmx;
      in
      {
        home.packages = [ zmxPkg ];
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
