{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = { allowUnfree = true; };
  };

  minecraftSecrets = import ./minecraft.secret.nix;

  serverSecrets = import ./server.secret.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ./users.secret.nix
    ./vm
    ./vivado-drivers.nix
    ./ci.nix
    ./media.nix
    ./restic-patched.nix
    ./backups.nix
    ./monitoring.nix
    ./nginx.nix
  ];

  disabledModules = [ "services/backup/restic.nix" ];

  hardware.cpu.amd.updateMicrocode = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.systemd-boot.consoleMode = "max";

  systemd.extraConfig = ''
    DefaultTimeoutStopSec=20s
  '';

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  # enable a module for collecting sensors
  boot.kernelModules = [ "nct6775" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv4.ip_forward" = true;
  };

  boot.initrd.kernelModules = [ "igb" "tun" ];
  boot.initrd.secrets = {
    "/root/tailscale.state" = ./tailscale.state;
  };

  boot.initrd.extraUtilsCommands = ''
    for BIN in ${pkgs.iproute2}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done

    for BIN in ${pkgs.iptables-legacy}/{s,}bin/*; do
      copy_bin_and_libs $BIN
    done

    copy_bin_and_libs ${pkgs.tailscale}/bin/.tailscaled-wrapped

    mkdir -p $out/secrets/etc/ssl/certs
    cp ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt $out/secrets/etc/ssl/certs/ca-bundle.crt
  '';

  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/boot/initrd_rsa_key" ];
      authorizedKeys = (import ./users.secret.nix { config = config; pkgs = pkgs; }).users.users.shadaj.openssh.authorizedKeys.keys;
    };

    postCommands = ''
      /bin/.tailscaled-wrapped --state /root/tailscale.state &

      zpool import tank
      zpool import swamp
      echo "zfs load-key -a; killall zfs; exit" >> /root/.profile
    '';
  };

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = super: let self = super.pkgs; in {
      tailscale = unstable.tailscale;
    };
  };

  networking.hostName = "kedar"; # Define your hostname.
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp6s0.useDHCP = true;
  networking.hostId = "d503793a";
  networking.interfaces.vmbridge0.useDHCP = true;
  networking.bridges.vmbridge0 = {
    interfaces = [ "enp6s0" ];
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    forwardX11 = true;
    extraConfig = ''
      AllowAgentForwarding yes
      X11Forwarding yes
      X11UseLocalHost no
    '';
  };

  services.sshd.enable = true;
  programs.ssh.startAgent = true;
  programs.mosh.enable = true;
  programs.nix-ld.enable = true;

  environment.variables = {
    NIX_LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc
    ];

    NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  users.extraGroups.vboxusers.members = [ "shadaj" ];

  environment.systemPackages = [
    config.services.samba.package
    pkgs.tailscale
    pkgs.xpra
  ];

  services.gvfs.enable = true;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.checkReversePath = "loose";
  networking.firewall.allowedTCPPorts = [ 9 ]; # time machine
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowPing = true;
  networking.firewall.extraCommands = ''
    iptables -I INPUT -i docker0 ! -s 192.168.0.0/24 -m addrtype --dst-type LOCAL -j DROP;
    iptables -I INPUT -i docker0 ! -s 192.168.0.0/24 -m addrtype --dst-type LOCAL -m state --state ESTABLISHED,RELATED -j ACCEPT;
    iptables -N DOCKER-USER || true;
    iptables -I DOCKER-USER -i docker0 -d 192.168.0.0/16 -j DROP;
    iptables -I DOCKER-USER -i docker0 -d 192.168.0.0/16 -m state --state ESTABLISHED,RELATED -j ACCEPT;
    iptables -I DOCKER-USER -i docker0 -d 100.64.0.0/10 -j DROP;
    iptables -I DOCKER-USER -i docker0 -d 100.64.0.0/10 -m state --state ESTABLISHED,RELATED -j ACCEPT;

    # Samba connectivity
    iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns
  '';

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.driSupport32Bit = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.deviceSection = ''
    Option "Coolbits" "12"
    Option "AllowEmptyInitialConfiguration" "True"
  '';

  # Enable the Gnome Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.autoSuspend = false;

  # Enable Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
  virtualisation.docker.extraOptions = "--config-file=${pkgs.writeText "daemon.json" (builtins.toJSON { dns = [ "1.1.1.1" "1.0.0.1" ]; })}";
  virtualisation.docker.enableNvidia = true;

  services.tailscale.enable = true;

  services.minecraft-server = {
    package = unstable.papermc;
    enable = false;
    eula = true;
    declarative = true;
    dataDir = "/tank/minecraft";
    openFirewall = true;

    serverProperties = {
      server-port = 25565;
      gamemode = "survival";
      motd = "PKcraft";
      max-players = 32;
      level-seed = "12345678";
      enable-rcon = true;
      "rcon.password" = minecraftSecrets.rconPass;
    };
  };

  users.groups.openvscode-server = {};

  systemd.services.openvscode-socket-folder = {
    wantedBy = [ "openvscode-server-shadaj.service" ];
    serviceConfig = {
      User = "root";
      ExecStart = "${pkgs.bash}/bin/bash -c \"mkdir /run/openvscode-server; chgrp openvscode-server /run/openvscode-server; chmod g+rw /run/openvscode-server\"";
    };
  };

  systemd.services.openvscode-server-shadaj = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "shadaj";
      Group = "openvscode-server";
      ExecStart = "${unstable.openvscode-server}/bin/openvscode-server --socket-path /run/openvscode-server/shadaj.sock --extensions-dir /home/shadaj/.vscode/extensions";
      ExecStartPost = "${pkgs.bash}/bin/bash -c \"until [ -e /run/openvscode-server/shadaj.sock ]; do sleep 1; done; chgrp openvscode-server /run/openvscode-server/shadaj.sock; chmod g+rw /run/openvscode-server/shadaj.sock\"";
    };
  };

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_13;
  services.postgresql.authentication = pkgs.lib.mkForce ''
    # TYPE  DATABASE        USER            ADDRESS                 METHOD

    # "local" is for Unix domain socket connections only
    local   all             all                                     trust
    # IPv4 local connections:
    host    all             all             127.0.0.1/32            trust
    # IPv6 local connections:
    host    all             all             ::1/128                 trust
    # Allow replication connections from localhost, by a user with the
    # replication privilege.
    local   replication     all                                     trust
    host    replication     all             127.0.0.1/32            trust
    host    replication     all             ::1/128                 trust
  '';

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    if type -q openvscode-server
      alias code="openvscode-server"
    end
  '';

  # for home-manager
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
