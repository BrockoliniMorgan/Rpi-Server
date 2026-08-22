{ hostName, nixpkgs, ... }:
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];
  sdImage.compressImage = false;
  image.fileName = "${hostName}-sdImage.img";
  sdImage.firmwareSize = 50;
}
