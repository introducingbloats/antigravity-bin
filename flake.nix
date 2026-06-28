{
  outputs =
    {
      self,
      ...
    }@inputs:
    let
      lib-nixpkgs = inputs.introducingbloats.lib.nixpkgs inputs;
    in
    {
      packages = lib-nixpkgs.forSystems lib-nixpkgs.linuxOnly (
        { pkgs, ... }:
        let
          packages = pkgs.callPackage ./package.nix { };
        in
        {
          default = packages.antigravity-bin;
          antigravity-bin = packages.antigravity-bin;
          antigravity-cli = packages.antigravity-cli;
          updateScript = pkgs.callPackage ./update.nix { };
        }
      );
    };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05-small";
    introducingbloats.url = "github:introducingbloats/core.flakes/main";
  };
}
