{
  lib,
  writeShellApplication,
  jq,
  coreutils,
  curl,
}:
let
  constants = lib.importJSON ./constants.json;
  downloadUrl =
    platform:
    "https://storage.googleapis.com/antigravity-public/antigravity-hub/${currentVersion.version}-${currentVersion.execution_id}/${platform}/Antigravity.tar.gz";
  cliManifestUrl =
    platform:
    "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/${platform}.json";
  # currentVersion is only used to make the GUI URL template available in Nix expression.
  currentVersion = lib.importJSON ./version.json;
in
writeShellApplication {
  name = "antigravity-bin-update";
  runtimeInputs = [
    jq
    coreutils
    curl
  ];
  text = ''
    set -euo pipefail
    echo "Fetching latest release information from ${constants.fetch_releases}"
    UPDATE_DATA=$(curl -sL ${constants.fetch_releases})

    VERSION=$(echo "$UPDATE_DATA" | jq -r '.[0].version')
    EXECUTION_ID=$(echo "$UPDATE_DATA" | jq -r '.[0].execution_id')
    echo "Latest version: $VERSION, execution ID: $EXECUTION_ID"

    echo "Fetching latest CLI manifest information"
    CLI_X64_DATA=$(curl -sL ${cliManifestUrl "linux_amd64"})
    CLI_ARM64_DATA=$(curl -sL ${cliManifestUrl "linux_arm64"})

    CLI_VERSION_X64=$(echo "$CLI_X64_DATA" | jq -r '.version')
    CLI_VERSION_ARM64=$(echo "$CLI_ARM64_DATA" | jq -r '.version')
    if [ "$CLI_VERSION_X64" != "$CLI_VERSION_ARM64" ]; then
      echo "CLI manifest versions differ between architectures"
      echo "x64: $CLI_VERSION_X64"
      echo "arm64: $CLI_VERSION_ARM64"
      exit 1
    fi
    CLI_VERSION="$CLI_VERSION_X64"

    CLI_URL_X64=$(echo "$CLI_X64_DATA" | jq -r '.url')
    CLI_URL_ARM64=$(echo "$CLI_ARM64_DATA" | jq -r '.url')

    # Fetch and validate GUI hashes
    echo "Fetching x86_64-linux tarball and calculating hash"
    X64_TARBALL=${downloadUrl "linux-x64"}
    X64_HASH=$(nix store prefetch-file --json "$X64_TARBALL" | jq -r '.hash')
    echo "x86_64-linux hash: $X64_HASH"

    echo "Fetching aarch64-linux tarball and calculating hash"
    ARM64_TARBALL=${downloadUrl "linux-arm"}
    ARM64_HASH=$(nix store prefetch-file --json "$ARM64_TARBALL" | jq -r '.hash')
    echo "aarch64-linux hash: $ARM64_HASH"

    # Fetch and validate CLI hashes directly from manifest urls (raw tarball hashes)
    echo "Fetching CLI x86_64-linux tarball and calculating hash"
    CLI_X64_HASH=$(nix store prefetch-file --json "$CLI_URL_X64" | jq -r '.hash')
    echo "CLI x86_64-linux hash: $CLI_X64_HASH"

    echo "Fetching CLI aarch64-linux tarball and calculating hash"
    CLI_ARM64_HASH=$(nix store prefetch-file --json "$CLI_URL_ARM64" | jq -r '.hash')
    echo "CLI aarch64-linux hash: $CLI_ARM64_HASH"

    # Check version, execution ID and CLI payload version + urls against current version.json and skip if they match
    CURRENT_VERSION=$(jq -r '.version' version.json)
    CURRENT_EXECUTION_ID=$(jq -r '.execution_id' version.json)
    CURRENT_CLI_VERSION=$(jq -r '.cli_version // ""' version.json)
    CURRENT_CLI_URL_X64=$(jq -r '."cli-url-linux-x64" // ""' version.json)
    CURRENT_CLI_URL_ARM64=$(jq -r '."cli-url-linux-arm64" // ""' version.json)

    echo "Flake version: $CURRENT_VERSION, execution ID: $CURRENT_EXECUTION_ID"
    echo "Flake CLI version: $CURRENT_CLI_VERSION"

    if [ "$VERSION" = "$CURRENT_VERSION" ] && [ "$EXECUTION_ID" = "$CURRENT_EXECUTION_ID" ] && [ "$CLI_VERSION" = "$CURRENT_CLI_VERSION" ] && [ "$CLI_URL_X64" = "$CURRENT_CLI_URL_X64" ] && [ "$CLI_URL_ARM64" = "$CURRENT_CLI_URL_ARM64" ]; then
      echo "Version, execution ID, and CLI release metadata match current version.json, skipping update"
      exit 0
    fi

    echo "Updating version.json with new version, hashes, and CLI metadata"
    jq --arg version "$VERSION" \
         --arg execution_id "$EXECUTION_ID" \
         --arg hash_linux_x64 "$X64_HASH" \
         --arg hash_linux_arm64 "$ARM64_HASH" \
         --arg cli_version "$CLI_VERSION" \
         --arg cli_url_x64 "$CLI_URL_X64" \
         --arg cli_url_arm64 "$CLI_URL_ARM64" \
         --arg hash_cli_linux_x64 "$CLI_X64_HASH" \
         --arg hash_cli_linux_arm64 "$CLI_ARM64_HASH" \
         '.version = $version |
          .execution_id = $execution_id |
          ."hash-linux-x64" = $hash_linux_x64 |
          ."hash-linux-arm64" = $hash_linux_arm64 |
          .cli_version = $cli_version |
          ."cli-url-linux-x64" = $cli_url_x64 |
          ."cli-url-linux-arm64" = $cli_url_arm64 |
          ."hash-cli-linux-x64" = $hash_cli_linux_x64 |
          ."hash-cli-linux-arm64" = $hash_cli_linux_arm64' \
         version.json > version.json.tmp
    mv version.json.tmp version.json
    echo "done updating version.json with new version, hashes, and CLI metadata"
  '';
}
