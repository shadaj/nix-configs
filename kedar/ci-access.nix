{ config, pkgs, secrets, ... }:

let
  ci-secrets = import secrets.ci-access;
in {
  networking.firewall.extraCommands = ''
    iptables -A INPUT  -i wgandy0 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
  '';

  networking.wireguard.interfaces.wgandy0 = {
    ips = [ "30.100.0.50/32" ];
    privateKey = ci-secrets.secret;

    peers = [
      {
        publicKey = "o9mO0KBUah+PoXxjmKxoYUMS6xrkVYzjVEChqzu/Wnc=";
        allowedIPs = [ "30.100.0.2/32" ];
        endpoint = "lolc.at:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
