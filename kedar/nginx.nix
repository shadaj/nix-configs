{ config, pkgs, secrets, ... }:

let
  serverSecrets = import secrets.server;
  tailsSecrets = import secrets.tails;
in {
  security.acme.acceptTerms = true;
  security.acme.defaults.email = serverSecrets.acmeEmail;
  security.acme.defaults = {
    dnsProvider = "cloudflare";
    credentialsFile = "/var/lib/secrets/certs.secret";
    dnsResolver = "1.1.1.1:53";
  };

  services.nginx.enable = true;
  services.nginx = {
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };

  systemd.services.nginx.serviceConfig = {
    SupplementaryGroups = [ "grafana" "openvscode-server" ];
  };

  services.nginx.virtualHosts."kedar.shadaj.me" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/".proxyPass = "http://unix:${config.services.grafana.settings.server.socket}";
    locations."/".proxyWebsockets = true;

    extraConfig = pkgs.lib.concatStringsSep "\n" (map (ip: ''
      allow ${ip};
    '') tailsSecrets."kedar.shadaj.me") + ''
      deny all;
    '';
  };

  services.nginx.virtualHosts."photos.kedar.shadaj.me" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/".proxyPass = "http://127.0.0.1:2342/";
    locations."/".proxyWebsockets = true;

    extraConfig = pkgs.lib.concatStringsSep "\n" (map (ip: ''
      allow ${ip};
    '') tailsSecrets."photos.kedar.shadaj.me") + ''
      deny all;
    '';
  };

  services.nginx.virtualHosts."ci.kedar.shadaj.me" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/".proxyPass = "http://127.0.0.1:3001/";
    locations."/".proxyWebsockets = true;

    extraConfig = pkgs.lib.concatStringsSep "\n" (map (ip: ''
      allow ${ip};
    '') tailsSecrets."ci.kedar.shadaj.me") + ''
      deny all;
    '';
  };

  services.nginx.virtualHosts."shadaj.code.kedar.shadaj.me" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/".proxyPass = "http://unix:/run/openvscode-server/shadaj.sock";
    locations."/".proxyWebsockets = true;

    extraConfig = pkgs.lib.concatStringsSep "\n" (map (ip: ''
      allow ${ip};
    '') tailsSecrets."shadaj.code.kedar.shadaj.me") + ''
      deny all;
    '';
  };

  services.nginx.virtualHosts."ramnivas.code.kedar.shadaj.me" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    locations."/".proxyPass = "http://unix:/run/openvscode-server/ramnivas.sock";
    locations."/".proxyWebsockets = true;

    extraConfig = pkgs.lib.concatStringsSep "\n" (map (ip: ''
      allow ${ip};
    '') tailsSecrets."ramnivas.code.kedar.shadaj.me") + ''
      deny all;
    '';
  };

  services.nginx.virtualHosts."bitwarden.kedar.shadaj.me" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;

    locations."/".proxyPass = "http://127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    locations."/".proxyWebsockets = true;

    extraConfig = pkgs.lib.concatStringsSep "\n" (map (ip: ''
      allow ${ip};
    '') tailsSecrets."bitwarden.kedar.shadaj.me") + ''
      deny all;
    '';
  };
}
