{ config, pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ ];

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = false;
  nix.package = pkgs.nix;

  homebrew = {
    enable = true;
    cleanup = "uninstall";

    taps = [
      "homebrew/cask"
      "homebrew/cask-versions"
      "homebrew/cask-drivers"
      "vitorgalvao/tiny-scripts"
    ];

    brews = [
      "automake" "bazel" "binwalk" "cmake" "ffmpeg" "gh" "ghostscript"
      "gnupg" "go" "gource" "handbrake" "highlight" "httpie" "maven" "mosh"
      "openrct2" "pngquant" "postgresql" "rsync" "ruby"
      "vitorgalvao/tiny-scripts/cask-repair" "youtube-dl"
    ];

    casks = [
      "android-file-transfer" "idrive" "skype" "android-sdk" "kap"
      "soundflower" "arduino" "logitech-options" "soundflowerbed" "backblaze"
      "mactex-no-gui" "spectacle" "background-music" "minecraft" "spotify"
      "balenaetcher" "miniconda" "visual-studio-code" "chromedriver" "monitorcontrol"
      "visualvm" "discord" "moonlight" "vlc" "docker" "ngrok" "webtorrent" "firefox"
      "obs" "wireshark" "ghidra" "osu-development" "xpra" "google-chrome" "parsec" "xquartz"
      "google-cloud-sdk" "screenflow" "zoom" "google-drive" "sidequest"
    ];
  };

  # Create /etc/bashrc that loads the nix-darwin environment.
  # programs.zsh.enable = true;  # default shell on catalina
  programs.fish.enable = true;

  nix.nixPath = pkgs.lib.mkForce [{
    darwin-config = builtins.concatStringsSep ":" [
      "$HOME/.nixpkgs/darwin-configuration.nix"
      "$HOME/.nix-defexpr/channels"
    ];
  }];

  users.nix.configureBuildUsers = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
