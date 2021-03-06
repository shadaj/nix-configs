{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = { allowUnfree = true; };
    overlays = [
      (self: super:
        {
          ethminer = super.ethminer.overrideAttrs (old: {
            version = "0.19.0";

            src =
              super.fetchFromGitHub {
                owner = "ethereum-mining";
                repo = "ethminer";
                rev = "v0.19.0";
                sha256 = "1kyff3vx2r4hjpqah9qk99z6dwz7nsnbnhhl6a76mdhjmgp1q646";
                fetchSubmodules = true;
              };

            cmakeFlags = old.cmakeFlags ++ [
              "-DCUDA_PROPAGATE_HOST_FLAGS=off"
              "-DCUDA_HOST_COMPILER=${super.gcc8}/bin"
            ];

            meta = old.meta // { broken = false; };
          });
        }
      )
    ];
  };

  miningSecrets = import ./mining.secret.nix;

  minecraftSecrets = import ./minecraft.secret.nix;

  backupSecrets = import ./backup.secret.nix;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./vm
      ./vivado-drivers.nix
      ./ci.nix
      ./users.secret.nix
      ./restic-patched.nix
      <nix-ld/modules/nix-ld.nix>
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

  boot.kernelPackages = pkgs.linuxPackages_5_12;
  # enable a module for collecting sensors
  boot.kernelModules = [ "nct6775" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  boot.initrd.kernelModules = [ "igb" ];
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/boot/initrd_rsa_key" ];
      authorizedKeys = (import ./users.secret.nix { config = config; pkgs = pkgs; }).users.users.shadaj.openssh.authorizedKeys.keys;
    };

    postCommands = ''
      zpool import swamp
      echo "zfs load-key -a; killall zfs; exit" >> /root/.profile
    '';
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "schedutil";
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = super: let self = super.pkgs; in {
      tailscale = unstable.tailscale;
      linuxPackages_5_12 = unstable.linuxPackages_5_12.extend (linuxSelf: linuxSuper:
      let
        generic = args: linuxSelf.callPackage (import <nixos-unstable/pkgs/os-specific/linux/nvidia-x11/generic.nix> args) { };
      in
      {
        nvidiaPackages.stable = generic {
          version = "465.31";
          sha256_64bit = "1nic4xvx5ihqijm2f57kg97nyh4nmfk7p3ikkh266n1kr40x0230";
          settingsSha256 = "1wgnag0d5g82vcmpwgz3rsx6w6q6yf48bsmi268xxzn62xgwfz6z";
          persistencedSha256 = "11n26vnzp33fqmyr7dj04fb0mirydh9ylf34x8vsz0xi6fmd1gyn";
        };
      });
      zfs = unstable.zfs;

      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    };
  };

  networking.hostName = "kedar"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp6s0.useDHCP = true;
  # networking.interfaces.wlp4s0.useDHCP = true;
  networking.hostId = "d503793a";

  networking.interfaces.vmbridge0.useDHCP = true;
  networking.bridges.vmbridge0.interfaces = [ "enp6s0" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  services.avahi = {
    enable = true;
    nssmdns = true;

    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };

    extraServiceFiles = {
      tm = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>9</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <port>9</port>
            <txt-record>dk0=adVN=Time Machine (kedar),adVF=0x82</txt-record>
            <txt-record>sys=adVF=0x100</txt-record>
          </service>
        </service-group>
      '';
    };
  };


  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    extraConfig = ''
      AllowAgentForwarding yes
      X11Forwarding yes
      X11UseLocalHost no
    '';
  };
  services.openssh.forwardX11 = true;
  services.sshd.enable = true;
  programs.ssh.startAgent = true;
  programs.mosh.enable = true;

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = kedar
      netbios name = kedar
      security = user
      hosts allow = 192.168. localhost
      guest account = nobody
      map to guest = bad user
      client min protocol = NT1
    '';
    shares = {
      media = {
        path = "/swamp/media";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
      };

      "Time Machine (kedar)" = {
        path = "/swamp/time-machine";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "vfs objects" = "catia fruit streams_xattr";
        "fruit:time machine" = "yes";
      };
    };
  };

  services.restic.backups.home = {
    paths = [ "/home" ];

    repository = "b2:kedar-restic:home";
    initialize = true;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--max-unused 5%"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [ "--verbose" ];

    timerConfig = {
      OnCalendar = "*-*-* 01:00:00";
    };

    s3CredentialsFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  services.restic.backups.media = {
    paths = [ "/swamp/media" ];

    repository = "b2:kedar-restic:media";
    initialize = true;

    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-monthly 12"
      "--max-unused 5%"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [ "--verbose" ];

    timerConfig = {
      OnCalendar = "*-*-* 02:00:00";
    };

    s3CredentialsFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  services.restic.backups.time-machine = {
    paths = [ "/swamp/time-machine" ];

    repository = "b2:kedar-restic:time-machine";
    initialize = true;

    pruneOpts = [
      "--keep-last 1"
      "--max-unused 5%"
    ];

    checkOpts = [ "--with-cache" ];

    extraBackupArgs = [ "--verbose" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
    };

    s3CredentialsFile = backupSecrets.s3CredentialsFile;
    passwordFile = backupSecrets.passwordFile;
  };

  environment.systemPackages = [
    config.services.samba.package
    pkgs.tailscale
    pkgs.xpra
  ];

  services.gvfs.enable = true;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    139 445 # samba
    9 # time machine
  ];
  networking.firewall.allowedUDPPorts = [
    137 138 # samba
    config.services.tailscale.port
  ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowPing = true;
  networking.firewall.extraCommands = ''
    iptables -I INPUT ! -s 192.168.0.0/24 -m addrtype --dst-type LOCAL -i docker0 -j DROP;
    iptables -I INPUT -i docker0 ! -s 192.168.0.0/24 -m addrtype --dst-type LOCAL -m state --state ESTABLISHED,RELATED -j ACCEPT;
    iptables -N DOCKER-USER;
    iptables -I DOCKER-USER -i docker0 -d 192.168.0.0/16 -j DROP;
    iptables -I DOCKER-USER -i docker0 -d 192.168.0.0/16 -m state --state ESTABLISHED,RELATED -j ACCEPT;

    iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns
  '';

  # Enable CUPS to print documents.
  # services.printing.enable = true;

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

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

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

  systemd.services.ethminer = {
    path = [ unstable.cudatoolkit ];
    description = "ethminer ethereum mining service";
    wantedBy = [ "multi-user.target" ];
    after = [ "display-manager.target" ];

    serviceConfig = {
      User = "root";
      Restart = "always";
    };

    environment = {
      LD_LIBRARY_PATH = "${config.boot.kernelPackages.nvidia_x11}/lib";
    };

    script = ''
      DISPLAY=:0 XAUTHORITY=/run/user/132/gdm/Xauthority ${pkgs.python37.interpreter} ${./mining/wrapper.py} ${unstable.ethminer}/bin/.ethminer-wrapped ${pkgs.lib.getBin config.boot.kernelPackages.nvidia_x11}/bin/nvidia-smi ${pkgs.lib.getBin config.boot.kernelPackages.nvidia_x11.settings}/bin/nvidia-settings stratum1+ssl://${miningSecrets.address}.${miningSecrets.identifier}@eth-us-west.flexpool.io:5555
    '';
  };

  services.minecraft-server = {
    package = unstable.papermc;
    enable = true;
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

  services.postgresql.enable = true;

  programs.fish.enable = true;

  # for home-manager
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?
}
