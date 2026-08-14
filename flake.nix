{
  inputs = {
    # TODO: Switch to stable. Didn't want to rebuild
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixos-hardware,
      nixpkgs,
      sops-nix,
      self,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      hostNames = builtins.concatLists (
        builtins.genList (i: [ "qutrc-pi-${lib.fixedWidthNumber 2 i}" ]) 8
      );
      createSystem = hostName: {
        ${hostName} = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-4 # This replaces hardware-configuration.nix
            sops-nix.nixosModules.sops
            ./system
          ];
          specialArgs = {
            inherit hostName;
          };
        };
      };
      # TODO: Clean this up to run over all self.nixosConfigurations
      # TODO: Consider adding hostPlatform and buildPlatform to reduce needed cross-compilation
      createSDSystem = hostName: {
        "${hostName}-sd" =
          ((createSystem hostName).${hostName}.extendModules {
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              {
                sdImage.compressImage = false;
                image.fileName = "${hostName}-sdImage.img";
              }
            ];
          }).config.system.build.sdImage;
      };
      applyToHostnames =
        function: (builtins.foldl' (acc: new: acc // new) { } (lib.map function hostNames));

    in
    {
      nixosConfigurations = applyToHostnames createSystem;
      packages.x86_64-linux = applyToHostnames createSDSystem;
    };
}
