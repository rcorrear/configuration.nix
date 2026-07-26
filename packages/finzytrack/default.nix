{
  appimageTools,
  fetchurl,
  fuse,
  gobject-introspection,
  gtk3,
  lib,
  libffi,
  libsoup_3,
  runCommand,
  sqlite,
  webkitgtk_4_1,
}:
let
  pname = "finzytrack";
  version = "0.2.1";

  src = fetchurl {
    url = "https://github.com/sagarbehere/finzytrack/releases/download/v${version}/Finzytrack-x86_64.AppImage";
    hash = "sha256-GtlZ6ur+TmjutXEL/zNkAKOruV0IirCzVFfcKP3MpAI=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };

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

  # The AppImage bundles neither its Python runtime dependencies nor the
  # WebKit/FUSE libraries required by its Tauri UI.
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
    "${giTypelibs}"
    "${appimageContents}/usr/bin/_internal/gi_typelibs"
    "--setenv"
    "GI_TYPELIB_PATH"
    "/usr/lib64/girepository-1.0"
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/finzytrack.desktop \
      $out/share/applications/finzytrack.desktop
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
