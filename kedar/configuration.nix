{ config, pkgs, ... }:

let
  unstable = import <nixos-unstable> {
    config = { allowUnfree = true; };
  };

  miningSecrets = import ./mining.secret.nix;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./vm
      ./vivado-drivers.nix
      ./ci.nix
      ./users.secret.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.copyKernels = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.loader.systemd-boot.consoleMode = "max";

  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  # Enable virtualisation through libvirt
  # also a module for collecting sensors
  boot.kernelPackages = pkgs.linuxPackages_5_8;
  boot.kernelModules = [ "kvm-amd" "kvm-intel" "nct6775" ];
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  virtualisation.libvirtd.enable = true;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    ethminer = unstable.ethminer;
  };

  networking.hostName = "kedar"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp5s0.useDHCP = true;
  networking.interfaces.wlp4s0.useDHCP = true;
  networking.hostId = "d503793a";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   wget vim
  # ];

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

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = kedar
      netbios name = kedar
      security = user
      hosts allow = 192.168.1. localhost
      guest account = nobody
      map to guest = bad user
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
    };
  };

  environment.systemPackages = [
    config.services.samba.package
    pkgs.tailscale
  ];

  # Open ports in the firewall.
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 445 139 ];
  networking.firewall.allowedUDPPorts = [ 137 138 ];
  networking.firewall.allowPing = true;
  networking.firewall.extraCommands = ''
    iptables -I INPUT ! -s 192.168.0.0/24 -m addrtype --dst-type LOCAL -i docker0 -j DROP;
    iptables -I INPUT -i docker0 ! -s 192.168.0.0/24 -m addrtype --dst-type LOCAL -m state --state ESTABLISHED,RELATED -j ACCEPT;
    iptables -N DOCKER-USER;
    iptables -I DOCKER-USER -i docker0 -d 192.168.0.0/16 -j DROP;
    iptables -I DOCKER-USER -i docker0 -d 192.168.0.0/16 -m state --state ESTABLISHED,RELATED -j ACCEPT;
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
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome3.enable = true;
  services.xserver.displayManager.gdm.autoSuspend = false;

  # Enable Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
  virtualisation.docker.extraOptions = "--config-file=${pkgs.writeText "daemon.json" (builtins.toJSON { dns = [ "1.1.1.1" "1.0.0.1" ]; })}";
  virtualisation.docker.enableNvidia = true;

  services.tailscale.enable = true;

  systemd.services.ethminer = {
    path = [ pkgs.cudatoolkit ];
    description = "ethminer ethereum mining service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      User = "root";
      Restart = "always";
    };

    environment = {
      LD_LIBRARY_PATH = "${config.boot.kernelPackages.nvidia_x11}/lib";
    };

    script = ''
      ${pkgs.python37.interpreter} ${./mining/wrapper.py} ${pkgs.ethminer}/bin/.ethminer-wrapped ${pkgs.lib.getBin config.boot.kernelPackages.nvidia_x11}/bin/nvidia-smi stratum1+ssl://${miningSecrets.address}.${miningSecrets.identifier}@eth-us-west.flexpool.io:5555
    '';
  };

  programs.fish.enable = true;
  programs.fish.shellInit = ''
    alias nix-fish="nix-shell --run fish";
  '';

  programs.bash.interactiveShellInit = ''
    exec fish -l;
  '';

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
