{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-26.05";
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
      username = "qutrc";
      hostNames = builtins.concatLists (
        builtins.genList (i: [ "qutrc-pi-${lib.fixedWidthNumber 2 i}" ]) 8
      );
      createSystem = hostName: {
        ${hostName} = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-3 # This replaces hardware-configuration.nix
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            {
              sdImage.compressImage = false;
              image.fileName = "${hostName}-sdImage.img";
              sdImage.firmwareSize = 50;
            }
            sops-nix.nixosModules.sops
            ./system
          ];
          specialArgs = {
            inherit hostName username;
          };
        };
      };
      createSDSystem = hostName: {
        "${hostName}-sd" = self.nixosConfigurations.${hostName}.config.system.build.sdImage;
      };
      applyToHostnames =
        function: (builtins.foldl' (acc: new: acc // new) { } (lib.map function hostNames));

    in
    {
      nixosConfigurations = applyToHostnames createSystem;
      packages.x86_64-linux = applyToHostnames createSDSystem;
    };
}
