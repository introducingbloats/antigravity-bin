{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,

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
    platform:
    "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/${currentVersion.version}-${currentVersion.execution_id}/${platform}/Antigravity.tar.gz";
  defaultArgs =
    {
      "x86_64-linux" = {
        src = fetchzip {
          url = downloadUrl "linux-x64";
          hash = currentVersion.hash-linux-x64;
        };
      };
      "aarch64-linux" = {
        src = fetchzip {
          url = downloadUrl "linux-arm";
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
  inherit (defaultArgs) src;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
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

    mkdir -p $out/lib/antigravity $out/bin
    cp -r * $out/lib/antigravity/

    # Expose only the main binary
    makeWrapper $out/lib/antigravity/antigravity $out/bin/antigravity

    # Install icon if present in the tarball
    for size in 16 24 32 48 64 128 256 512; do
      if [ -f "$out/lib/antigravity/resources/icons/''${size}x''${size}.png" ]; then
        install -Dm644 "$out/lib/antigravity/resources/icons/''${size}x''${size}.png" \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/antigravity.png"
      fi
    done
    # Fallback: try common icon locations
    if [ -f "$out/lib/antigravity/resources/icon.png" ]; then
      install -Dm644 "$out/lib/antigravity/resources/icon.png" \
        "$out/share/icons/hicolor/256x256/apps/antigravity.png"
    fi

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "antigravity";
      desktopName = "Antigravity";
      exec = "antigravity %U";
      icon = "antigravity";
      comment = "Antigravity by Google";
      categories = [ "Utility" ];
      startupWMClass = "Antigravity";
    })
  ];

  meta = {
    description = "Antigravity by Google";
    homepage = "https://antigravity.google";
    license = lib.licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.platforms.linux;
    mainProgram = "antigravity";
  };
})
