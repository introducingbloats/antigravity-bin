{
  lib,
  stdenv,
  fetchurl,
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

  guiDownloadUrl =
    platform:
    "https://storage.googleapis.com/antigravity-public/antigravity-hub/${currentVersion.version}-${currentVersion.execution_id}/${platform}/Antigravity.tar.gz";

  guiDefaultArgs =
    {
      "x86_64-linux" = {
        src = fetchurl {
          url = guiDownloadUrl "linux-x64";
          hash = currentVersion.hash-linux-x64;
        };
      };
      "aarch64-linux" = {
        src = fetchurl {
          url = guiDownloadUrl "linux-arm";
          hash = currentVersion.hash-linux-arm64;
        };
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "antigravity-bin: Unsupported platform: ${stdenv.hostPlatform.system}");

  gui = stdenv.mkDerivation (finalAttrs: {
    pname = "antigravity-bin";
    version = currentVersion.version;
    inherit (guiDefaultArgs) src;

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

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;
    noDumpEnvVars = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/antigravity $out/bin
      tar -xzf "$src"
      cp -r Antigravity-*/* $out/lib/antigravity/

      # Expose only the main binary
      makeWrapper $out/lib/antigravity/antigravity $out/bin/antigravity

      # Install icon if present in the tarball
      for size in 16 24 32 48 64 128 256 512; do
        icon_size="$size"x"$size"
        if [ -f "$out/lib/antigravity/resources/icons/$icon_size.png" ]; then
          install -Dm644 "$out/lib/antigravity/resources/icons/$icon_size.png" \
            "$out/share/icons/hicolor/$icon_size/apps/antigravity.png"
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
  });

  cliDownloadUrl =
    platform:
    currentVersion."cli-url-${platform}";
  cliDefaultArgs =
    {
      "x86_64-linux" = {
        src = fetchurl {
          url = cliDownloadUrl "linux-x64";
          hash = currentVersion."hash-cli-linux-x64";
        };
      };
      "aarch64-linux" = {
        src = fetchurl {
          url = cliDownloadUrl "linux-arm64";
          hash = currentVersion."hash-cli-linux-arm64";
        };
      };
    }
    .${stdenv.hostPlatform.system}
      or (throw "antigravity-cli: Unsupported platform: ${stdenv.hostPlatform.system}");

  cli = stdenv.mkDerivation (finalAttrs: {
    pname = "antigravity-cli";
    version = currentVersion.cli_version;
    inherit (cliDefaultArgs) src;

    nativeBuildInputs = [
      autoPatchelfHook
    ];

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;
    noDumpEnvVars = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      tar -xzf "$src" antigravity
      install -Dm755 antigravity $out/bin/agy
      install -Dm755 antigravity $out/bin/antigravity-cli

      runHook postInstall
    '';

    meta = {
      description = "Antigravity CLI";
      homepage = "https://antigravity.google";
      license = lib.licenses.unfreeRedistributable;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
      platforms = lib.platforms.linux;
      mainProgram = "antigravity-cli";
    };
  });
in
{
  antigravity-bin = gui;
  antigravity-cli = cli;
}
