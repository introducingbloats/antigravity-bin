{
  lib,
  nix-prefetch-scripts,
  writeShellApplication,
  jq,
  coreutils,
}:
let
  constants = lib.importJSON ./constants.json;
  downloadUrl =
    platform:
    "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/$VERSION-$EXECUTION_ID/${platform}/Antigravity.tar.gz";
in
writeShellApplication {
  name = "antigravity-bin-update";
  runtimeInputs = [
    jq
    nix-prefetch-scripts
    coreutils
  ];
  text = ''
    set -euo pipefail
    echo "Fetching latest release information from ${constants.fetch_releases}"
    UPDATE_DATA=$(curl -sL ${constants.fetch_releases})

    VERSION=$(echo "$UPDATE_DATA" | jq -r '.[0].version')
    EXECUTION_ID=$(echo "$UPDATE_DATA" | jq -r '.[0].execution_id')
    echo "Latest version: $VERSION, execution ID: $EXECUTION_ID"

    echo "Fetching x86_64-linux tarball and calculating hash"
    X64_TARBALL=${downloadUrl "linux-x64"}
    X64_SHA256=$(nix-prefetch-url --unpack "$X64_TARBALL")
    X64_HASH=$(nix-hash --to-sri --type sha256 "$X64_SHA256")
    echo "x86_64-linux hash: $X64_HASH"

    echo "Fetching aarch64-linux tarball and calculating hash"
    ARM64_TARBALL=${downloadUrl "linux-arm"}
    ARM64_SHA256=$(nix-prefetch-url --unpack "$ARM64_TARBALL")
    ARM64_HASH=$(nix-hash --to-sri --type sha256 "$ARM64_SHA256")
    echo "aarch64-linux hash: $ARM64_HASH"

    # Write the new version and hashes to version.json.tmp and then move it to version.json
    echo "Updating version.json with new version and hashes"
    jq --arg version "$VERSION" \
         --arg execution_id "$EXECUTION_ID" \
         --arg hash_linux_x64 "$X64_HASH" \
         --arg hash_linux_arm64 "$ARM64_HASH" \
         '.version = $version |
          .execution_id = $execution_id |
          ."hash-linux-x64" = $hash_linux_x64 |
          ."hash-linux-arm64" = $hash_linux_arm64' \
         version.json > version.json.tmp
    mv version.json.tmp version.json
    echo "done updating version.json with new version and hashes"
  '';
}
