{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,

  libgcc,
  glib,
  nspr,
  nss,
  dbus,
  at-spi2-atk,
  cups,
  cairo,
  gtk3,
  pango,
  libxcomposite,
  libxdamage,
  libxfixes,
  libxrandr,
  libgbm,
  libxkbcommon,
  alsa-lib,
  curl,
  openssl,
  webkitgtk_4_1,
  libsoup_3,
  libsecret,
  libxkbfile,
}:
let
  currentVersion = lib.importJSON ./version.json;
  downloadUrl =
    platform: version:
    "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${version.version}-${version.execution_id}/${platform}/Antigravity.tar.gz";
  sets =
    {
      "x86_64-linux" = {
        src = fetchzip {
          url = downloadUrl "linux-x64" currentVersion;
          hash = currentVersion.hash-linux-x64;
        };
      };
      "aarch64-linux" = {
        src = fetchzip {
          url = downloadUrl "linux-arm" currentVersion;
          hash = currentVersion.hash-linux-arm64;
        };
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "antigravity-bin: Unsupported platform: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation (finalAttrs: {
  pname = "antigravity-bin";
  version = currentVersion.version;
  inherit (sets) src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    libgcc
    glib
    nspr
    nss
    dbus
    at-spi2-atk
    cups
    cairo
    gtk3
    pango
    libxcomposite
    libxdamage
    libxfixes
    libxrandr
    libgbm
    libxkbcommon
    alsa-lib
    curl
    openssl
    webkitgtk_4_1
    libsoup_3
    libsecret
    libxkbfile
  ];

  dontBuild = true;
  dontConfigure = true;
  noDumpEnvVars = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r * $out/
  '';

  meta = {
    homepage = "https://antigravity.google";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.linux;
  };
})
