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

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.registry.nixpkgs-unstable.flake = inputs.inputs.nixpkgs-unstable;
  nix.nixPath = [
    "nixpkgs=${inputs.nixpkgs}"
    "nixos-unstable=${inputs.inputs.nixpkgs-unstable}"
  ];

  homebrew = {
    enable = true;
    onActivation.cleanup = "uninstall";
    onActivation.upgrade = true;

    casks = [
      "kap" "arc" "logi-options-plus" "rectangle"
      "balenaetcher" "visual-studio-code" "monitorcontrol"
      "iterm2" "vlc" "docker"
      "obs" "wireshark" "xpra"
      "xquartz" "zoom" "zotero" "utm" "raycast"
    ] ++ (if inputs.host == "sarang" then [
      "loom" "signal" "spotify" "google-chrome"
      "google-drive" "signal" "openrct2" "moonlight" "osu" "sidequest"
      "firefox" "adobe-creative-cloud" "steam"
    ] else []);
  };

  services.postgresql = {
    enable = true;
    dataDir = "/usr/local/var/postgres";
    package = pkgs.postgresql_13;
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
