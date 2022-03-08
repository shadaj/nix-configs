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
      "homebrew/cask"
      "homebrew/cask-versions"
      "homebrew/cask-drivers"
    ];

    casks = [
      "aerial" "android-file-transfer" "handbrake" "kap" "slack"
      "logitech-options" "rectangle" "background-music" "openrct2" "spotify"
      "balenaetcher" "visual-studio-code" "monitorcontrol"
      "discord" "iterm2" "moonlight" "notion" "vlc" "docker"
      "obs" "wireshark" "osu-development" "xpra" "element"
      "google-chrome" "firefox" "xquartz" "zoom" "google-drive" "sidequest"
    ];
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

  users.nix.configureBuildUsers = false;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
