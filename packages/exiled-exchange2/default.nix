{
  # Snowfall Lib provides a customized `lib` instance with access to your flake's library
  # as well as the libraries available from your flake's inputs.
  lib,

  # All other arguments come from NixPkgs. You can use `pkgs` to pull packages or helpers
  # programmatically or you may add the named attributes as arguments here.
  appimageTools,
  fetchurl,
  ...
}:

let
  version = "0.6.2";
  pname = "exiled-exchange2";
  src = fetchurl {
    inherit pname;
    url = "https://github.com/Kvan7/Exiled-Exchange-2/releases/download/v0.6.2/Exiled-Exchange-2-0.6.2.AppImage";
    sha256 = "poGUsTNgCL7CVQtv7wjfTTVxwd20K4WjA7j50uNOYAE=";
  };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  # extraInstallCommands = ''
  #   substituteInPlace $out/share/applications/${pname}.desktop \
  #     --replace-fail 'Exec=AppRun' 'Exec=${meta.mainProgram}'
  # '';

  meta = {
    description = "Path of Exile 2 trading app for price checking (aka EE2)";
    homepage = "https://github.com/Kvan7/Exiled-Exchange-2";
    downloadPage = "https://github.com/Kvan7/Exiled-Exchange-2/releases";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
  };
}
