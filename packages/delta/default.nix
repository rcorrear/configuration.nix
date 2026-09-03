{
  autoPatchelfHook,
  lib,
  libGL,
  makeWrapper,
  requireFile,
  stdenv,
  vulkan-loader,
  wayland,
  xkeyboard_config,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "delta";
  version = "0.11.0";

  src = requireFile {
    name = "delta-linux-x86_64.tar.gz";
    url = "https://zed.dev/delta";
    sha256 = "sha256-SxFgVJeynObM/zfXcvc3oGe1vLDl7b3hwegYfepii+Q=";
  };

  sourceRoot = "Delta";
  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  runtimeDependencies = [
    libGL
    vulkan-loader
    wayland
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/delta $out/bin/delta
    cp -a lib $out/lib
    cp -a share $out/share
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/delta \
      --set XKB_CONFIG_ROOT "${xkeyboard_config}/share/X11/xkb"
  '';

  meta = {
    description = "AI-native code editor";
    homepage = "https://zed.dev/delta";
    license = lib.licenses.unfree;
    mainProgram = "delta";
    platforms = [ "x86_64-linux" ];
  };
})
