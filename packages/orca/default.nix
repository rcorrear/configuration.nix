{
  appimageTools,
  fetchurl,
  lib,
  stdenv,
}:
let
  version = "1.4.197";
  sources = {
    x86_64-linux = {
      url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
      hash = "sha256-S8hGLRUf8BD6pUxka7FtzFR0v2ZO7V7FAoGC15kmQWs=";
    };
    aarch64-linux = {
      url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux-arm64.AppImage";
      hash = "sha256-Vo8ToY3xO9bLm/ooE6MLFzZZbnLhwYaaz9Rvv2DCC2k=";
    };
  };
in
appimageTools.wrapType2 rec {
  pname = "orca";
  inherit version;
  src = fetchurl sources.${stdenv.hostPlatform.system};

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
    in
    ''
      install -Dm444 ${contents}/orca-ide.desktop \
        $out/share/applications/orca-ide.desktop
      substituteInPlace $out/share/applications/orca-ide.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=orca'
      install -Dm444 ${contents}/usr/share/icons/hicolor/512x512/apps/orca-ide.png \
        $out/share/icons/hicolor/512x512/apps/orca-ide.png
    '';

  meta = {
    description = "AI development environment for orchestrating coding agents";
    homepage = "https://github.com/stablyai/orca";
    license = lib.licenses.mit;
    mainProgram = "orca";
    platforms = builtins.attrNames sources;
  };
}
