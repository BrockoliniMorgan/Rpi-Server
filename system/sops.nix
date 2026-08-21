{ username, config, ... }:
{
  sops.defaultSopsFile = ./../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.keyFile = "/home/${username}/.config/sops/age/keys.txt";

  sops.secrets."rpi/age-key".path = config.sops.age.keyFile;
}
