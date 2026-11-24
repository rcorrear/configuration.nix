{
  pkgs,
  nimi,
  nix2container,
  secretRuntime,
}:
let
  package = pkgs.callPackage ./. { };
  root = pkgs.runCommand "9router-image-root" { } ''
    mkdir -p $out/tmp $out/run/secrets $out/var/lib/9router $out/etc
    cat > $out/etc/passwd <<'EOF'
    root:x:0:0:root:/root:/sbin/nologin
    9router:x:1000:1000:9Router:/var/lib/9router:/sbin/nologin
    EOF
    cat > $out/etc/group <<'EOF'
    root:x:0:
    9router:x:1000:
    EOF
  '';
  module = {
    services."9router".imports = [
      (pkgs.lib.modules.importApply ./service.nix { inherit package pkgs secretRuntime; })
    ];
    settings = {
      binName = "9router-nimi";
      restart = {
        mode = "always";
        time = 10000;
      };
      container = {
        name = "9router";
        tag = package.version;
        copyToRoot = [ root ];
        imageConfig = {
          # Container root resolves secrets; application code still runs as 1000.
          User = "0:0";
          WorkingDir = "/";
          Env = [
            "HOME=/var/lib/9router"
            "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            "NODE_EXTRA_CA_CERTS=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          ];
          ExposedPorts."20128/tcp" = { };
          Volumes."/var/lib/9router" = { };
          Labels."org.opencontainers.image.version" = package.version;
        };
      };
    };
  };
  runner = nimi.mkNimiBin module;
in
{
  inherit runner;
  # Nimi's pinned perms submodule is malformed. Compose its supported runner
  # with nix2container directly so /tmp can have normal container permissions.
  image = nix2container.buildImage {
    inherit (module.settings.container) name tag copyToRoot;
    config = module.settings.container.imageConfig // {
      entrypoint = [ (pkgs.lib.getExe runner) ];
    };
    perms = [
      {
        path = root;
        regex = "/tmp";
        mode = "1777";
      }
    ];
  };
}
