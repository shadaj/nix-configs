{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = false;
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

    brews = [ "openrct2" "postgresql" ];

    casks = [
      "android-file-transfer" "handbrake" "skype" "android-sdk" "kap"
      "soundflower" "logitech-options" "soundflowerbed" "backblaze"
      "spectacle" "background-music" "minecraft" "spotify"
      "balenaetcher" "visual-studio-code" "chromedriver" "monitorcontrol"
      "visualvm" "discord" "moonlight" "vlc" "docker" "ngrok" "firefox"
      "obs" "wireshark" "osu-development" "xpra" "google-chrome" "xquartz"
      "screenflow" "zoom" "google-drive" "sidequest"
    ];
  };

  # Create profile that loads the nix-darwin environment.
  programs.fish.enable = true;

  users.nix.configureBuildUsers = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
