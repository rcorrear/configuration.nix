{
  hermes-agent,
  lib,
  python3Packages,
  ripgrep,
  git,
  openssh,
  ffmpeg,
}:
let
  matrixNioWithE2E = python3Packages."matrix-nio".overridePythonAttrs (old: {
    doCheck = false;
    propagatedBuildInputs =
      (old.propagatedBuildInputs or [ ])
      ++ (with python3Packages; [
        python3Packages."python-olm"
        peewee
        cachetools
        aiofiles
        atomicwrites
      ]);
  });
in

hermes-agent.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    cp -r ${old.src}/plugins/. $out/${python3Packages.python.sitePackages}/plugins/
  '';
  postInstallCheck = (old.postInstallCheck or "") + ''
    test -f $out/${python3Packages.python.sitePackages}/plugins/platforms/matrix/plugin.yaml
    grep -q HERMES_BUNDLED_PLUGINS $out/bin/hermes
  '';
  propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ matrixNioWithE2E ];
  makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [
    "--set"
    "HERMES_BUNDLED_PLUGINS"
    "${placeholder "out"}/${python3Packages.python.sitePackages}/plugins"
    "--suffix"
    "PATH"
    ":"
    (lib.makeBinPath [
      ripgrep
      git
      openssh
      ffmpeg
    ])
  ];
})
