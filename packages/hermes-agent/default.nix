{
  hermes-agent,
  lib,
  ripgrep,
  git,
  openssh,
  ffmpeg,
}:

hermes-agent.overrideAttrs (old: {
  # Upstream supplies the Matrix stack and bundled plugins. Do not append
  # Python dependencies from the host's separate nixpkgs package set.
  pythonImportsCheck = (old.pythonImportsCheck or [ ]) ++ [
    "mautrix.client"
    "mautrix.crypto"
    "mautrix.crypto.store.asyncpg"
    "olm"
  ];
  postInstallCheck = (old.postInstallCheck or "") + ''
    test -f $out/share/hermes/plugins/platforms/matrix/plugin.yaml
    grep -q HERMES_BUNDLED_PLUGINS $out/bin/hermes
  '';
  makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [
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
