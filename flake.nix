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
    }@inputs:
    let
      inherit (nixpkgs) lib;
      username = "qutrc";
      piHostNames = builtins.concatLists (
        builtins.genList (i: [ "qutrc-pi-${lib.fixedWidthNumber 2 i}" ]) 8
      );
      serverHostNames = [
        "katherine"
        "mary"
      ];
      createSystemTemplate =
        system: hostName:
        lib.nixosSystem {
          inherit system;
          modules = [
            sops-nix.nixosModules.sops
            ./system
          ];
          specialArgs = {
            inherit hostName username;
          }
          // inputs;
        };
      createPiSystem = hostName: {
        ${hostName} = (createSystemTemplate "aarch64-linux" hostName).extendModules {
          modules = [
            nixos-hardware.nixosModules.raspberry-pi-3 # This replaces hardware-configuration.nix
            ./system/rpi
          ];
        };
      };
      createPiSDSystem = hostName: {
        "${hostName}-sd" = self.nixosConfigurations.${hostName}.config.system.build.sdImage;
      };
      createServerSystem = hostName: {
        ${hostName} = (createSystemTemplate "x86_64-linux" hostName).extendModules {
          modules = [
            ./hardware
          ];
        };
      };
      applyToList = list: function: (builtins.foldl' (acc: new: acc // new) { } (lib.map function list));
      applyToPiHostNames = applyToList piHostNames;
      applyToServerHostNames = applyToList serverHostNames;
    in
    {
      nixosConfigurations =
        applyToPiHostNames createPiSystem // applyToServerHostNames createServerSystem;
      packages.x86_64-linux = applyToPiHostNames createPiSDSystem;
    };
}
