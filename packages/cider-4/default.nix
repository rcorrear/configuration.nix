{
  appimageTools,
  lib,
  requireFile,
  makeWrapper,
}:

appimageTools.wrapType2 rec {
  pname = "cider-4";
  version = "4.0.17";

  src = requireFile {
    name = "cider-v4.0.17-linux-x64.AppImage";
    url = "https://cidercollective.itch.io/cider";
    sha256 = "sha256-P7E5iSqur9socAPQ+lVXQ7cOVi7knPGGlYDzdLbbq5E=";
  };

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands =
    let
      contents = appimageTools.extract {
        inherit version src;
        # The AppImage uses Cider.desktop rather than ${pname}.desktop.
        pname = "Cider";
      };
    in
    ''
      wrapProgram $out/bin/${pname} \
         --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
         --add-flags "--no-sandbox --disable-gpu-sandbox" # Cider 2 does not start up properly without these from my preliminary testing

      install -m 444 -D ${contents}/Cider.desktop $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-warn 'Exec=Cider' 'Exec=${pname}'
      install -Dm444 ${contents}/usr/share/icons/hicolor/256x256/apps/Cider.png \
                     $out/share/icons/hicolor/256x256/apps/cider.png
    '';

  meta = {
    description = "Powerful music player that allows you listen to your favorite tracks with style";
    homepage = "https://cider.sh";
    license = lib.licenses.unfree;
    mainProgram = "cider-4";
    maintainers = with lib.maintainers; [ itsvic-dev ];
    platforms = [ "x86_64-linux" ];
  };
}
