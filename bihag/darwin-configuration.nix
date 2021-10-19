{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.useDaemon = true;
  nix.package = pkgs.nix;

  homebrew = {
    enable = true;
    cleanup = "uninstall";

    taps = [
      "homebrew/services"
      "homebrew/cask"
      "homebrew/cask-versions"
      "homebrew/cask-drivers"
    ];

    brews = [ "postgresql" ];

    casks = [
      "aerial" "android-file-transfer" "handbrake" "kap"
      "logitech-options" "spectacle" "background-music" "openrct2" "spotify"
      "balenaetcher" "visual-studio-code" "monitorcontrol"
      "discord" "iterm2" "moonlight" "notion" "vlc" "docker"
      "obs" "wireshark" "osu-development" "xpra"
      "google-chrome" "xquartz" "zoom" "google-drive" "sidequest"
    ];
  };

  # Create profile that loads the nix-darwin environment.
  programs.fish.enable = true;

  users.nix.configureBuildUsers = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
