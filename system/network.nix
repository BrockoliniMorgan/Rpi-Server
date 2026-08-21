{ config, pkgs, ... }:
{
  sops.secrets."network/ssid" = { };
  sops.secrets."network/password" = { };
  sops.secrets."network/username" = { };

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [
      config.sops.secrets."network/ssid".path
      config.sops.secrets."network/password".path
      config.sops.secrets."network/username".path
    ];
    profiles = {
      network = {
        "802-1x" = {
          ca-cert = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          eap = "peap;";
          identity = "$USERNAME";
          password = "$PASSWORD";
          phase2-auth = "mschapv2";
        };
        connection = {
          id = "$SSID";
          type = "wifi";
        };
        ipv4.method = "auto";
        ipv6 = {
          addr-gen-mode = "default";
          method = "auto";
        };
        wifi = {
          mode = "infrastructure";
          ssid = "$SSID";
        };
        wifi-security = {
          key-mgmt = "wpa-eap";
        };
      };
    };
  };
}
