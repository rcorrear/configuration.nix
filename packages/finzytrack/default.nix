{
  appimageTools,
  coreutils,
  fetchurl,
  fuse,
  gobject-introspection,
  gtk3,
  lib,
  libffi,
  libsoup_3,
  makeWrapper,
  runCommand,
  sqlite,
  webkitgtk_4_1,
  writeShellScript,
}:
let
  pname = "finzytrack";
  version = "0.2.1";

  src = fetchurl {
    url = "https://github.com/sagarbehere/finzytrack/releases/download/v${version}/Finzytrack-x86_64.AppImage";
    hash = "sha256-GtlZ6ur+TmjutXEL/zNkAKOruV0IirCzVFfcKP3MpAI=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };

  # copy2/copytree preserve source modes. Store-backed seed files would make
  # config and ledgers read-only, including before currency substitution.
  launcher = writeShellScript "finzytrack-launcher" ''
    set -euo pipefail
    wrapped="$1"
    shift
    export FINZYTRACK_SEED_DIR
    FINZYTRACK_SEED_DIR="$(${coreutils}/bin/mktemp -d -t finzytrack-seeds.XXXXXXXX)"
    trap '${coreutils}/bin/rm -rf -- "$FINZYTRACK_SEED_DIR"' EXIT
    ${coreutils}/bin/cp -R \
      ${appimageContents}/usr/bin/_internal/backend/seed_config \
      ${appimageContents}/usr/bin/_internal/backend/seed_data \
      "$FINZYTRACK_SEED_DIR/"
    ${coreutils}/bin/chmod -R u+w "$FINZYTRACK_SEED_DIR"
    "$wrapped" "$@"
  '';

  giTypelibs = runCommand "finzytrack-gi-typelibs" { } ''
    mkdir -p $out
    cp -L ${appimageContents}/usr/bin/_internal/gi_typelibs/* $out/
    cp -L ${webkitgtk_4_1}/lib/girepository-1.0/JavaScriptCore-4.1.typelib $out/
    cp -L ${libsoup_3}/lib/girepository-1.0/Soup-3.0.typelib $out/
    cp -L ${webkitgtk_4_1}/lib/girepository-1.0/WebKit2-4.1.typelib $out/
  '';
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Supply the system libraries required by the bundled Python runtime and
  # its PyWebView UI.
  extraPkgs = _: [
    fuse
    gobject-introspection
    gtk3
    libffi
    libsoup_3
    sqlite
    webkitgtk_4_1
  ];

  # PyGObject searches the bundled directory before the system paths. Extend
  # it with WebKit's typelib by overlaying a merged, read-only directory.
  extraBwrapArgs = [
    "--ro-bind"
    ''"$FINZYTRACK_SEED_DIR"''
    "${appimageContents}/usr/bin/_internal/backend"
    "--ro-bind"
    "${giTypelibs}"
    "${appimageContents}/usr/bin/_internal/gi_typelibs"
    "--setenv"
    "GI_TYPELIB_PATH"
    "/usr/lib64/girepository-1.0"
  ];

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    mkdir -p $out/libexec
    mv $out/bin/finzytrack $out/libexec/finzytrack
    makeWrapper ${launcher} $out/bin/finzytrack \
      --add-flags "$out/libexec/finzytrack"
    install -Dm444 ${appimageContents}/finzytrack.desktop \
      $out/share/applications/finzytrack.desktop
    substituteInPlace $out/share/applications/finzytrack.desktop \
      --replace-fail "Exec=Finzytrack" "Exec=finzytrack"
    install -Dm444 ${appimageContents}/finzytrack.png \
      $out/share/icons/hicolor/512x512/apps/finzytrack.png
  '';

  meta = {
    description = "Plain-text Beancount personal finance application";
    homepage = "https://github.com/sagarbehere/finzytrack";
    downloadPage = "https://github.com/sagarbehere/finzytrack/releases";
    license = lib.licenses.mit;
    mainProgram = "finzytrack";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
