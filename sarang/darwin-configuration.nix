{ config, pkgs, inputs, host, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.useDaemon = true;
  nix.package = pkgs.nix;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.registry.nixpkgs-unstable.flake = inputs.nixpkgs-unstable;
  nix.registry.nixos-unstable.flake = inputs.nixpkgs-unstable;
  nix.nixPath = [
    "nixpkgs-unstable=${inputs.nixpkgs-unstable}"
    "nixos-unstable=${inputs.nixpkgs-unstable}"
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.upgrade = true;

    casks = [
      "arc" "logi-options+" "rectangle"
      "visual-studio-code" "monitorcontrol"
      "iterm2" "vlc" "docker"
      "obs" "wireshark" "zoom" "zotero" "utm" "raycast"
    ] ++ (if inputs.host == "sarang" then [
      "signal" "spotify" "google-drive" "signal" "openrct2" "moonlight" "osu"
      "firefox" "adobe-creative-cloud" "steam" "dolphin"
    ] else []);
  };

  services.postgresql = {
    enable = true;
    dataDir = "/usr/local/var/postgres";
    package = (inputs.postgresPackage pkgs);
    extraPlugins = (inputs.postgresPlugins pkgs);
  };

  # Create profile that loads the nix-darwin environment.
  programs.fish.enable = true;

  # https://github.com/LnL7/nix-darwin/issues/122
  environment.etc."fish/nixos-env-preinit.fish".text = pkgs.lib.mkMerge [
    (pkgs.lib.mkBefore ''
      set -l oldPath $PATH
    '')
    (pkgs.lib.mkAfter ''
      for elt in $PATH
        if not contains -- $elt $oldPath /usr/local/bin /usr/bin /bin /usr/sbin /sbin
          set -ag fish_user_paths $elt
        end
      end
      set -el oldPath
    '')
  ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
