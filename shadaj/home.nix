{ config, pkgs, unstable, host, isDarwin, ... }:

with pkgs; # bring all of Nixpkgs into scope

let
  javaPkg = openjdk25;
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  xdg = if host == "kedar" then {
    enable = true;
    mime.enable = true;
  } else {};

  nixpkgs.config = {
    allowUnfree = true;
  };

  programs.bash.enable = true;
  programs.fish = {
    enable = true;
    interactiveShellInit = (builtins.readFile ./fish-prompt.fish);
    shellInit = ''
      set PATH ~/bin $PATH
      set PATH $HOME/.cargo/bin $PATH
      set PATH /opt/homebrew/bin $PATH
      alias nix-fish="nix-shell --run fish"
      source ~/bin/iterm2_shell_integration.fish
    '' + (if host == "kedar" then '''' else if host == "sarang" then ''
      alias matlab="/Applications/MATLAB_R2019b.app/bin/matlab -nodesktop"
    '' else '''');
  };

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Shadaj Laddad";
        email = "shadaj@users.noreply.github.com";
      };

      pull = {
        rebase = "false";
      };

      init = {
        defaultBranch = "main";
      };
    };

    ignores = [
      "shell.nix" ".direnv/" ".envrc" ".venv/"
      "metals.sbt" ".bloop/" ".bsp/" ".metals/"
      ".sl/"
      ".vsls.json"
      ".vscode/"
    ] ++ (if isDarwin then [ ".DS_Store" ] else []);

    lfs = {
      enable = true;
    };
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.java.enable = true;
  programs.java.package = javaPkg;

  services = if host == "kedar" then {
    vscode-server = {
      enable = true;
    };
  } else {};

  home.packages = [
    nodejs_22

    git
    sapling
    watchman
    gh

    (sbt.override {
      jre = javaPkg;
    })
    rustup
    ruby
    go
    z3
    coq
    octave
    python3
    protobuf
    elan
    nixd

    (clang.overrideAttrs (attrs: {
      # lower priority than binutils
      meta.priority = binutils.meta.priority + 1;
    }))
    (gcc.overrideAttrs (attrs: {
      # lower priority than binutils and clang
      meta.priority = binutils.meta.priority + 2;
    }))
    automake
    gnumake
    cmake
    uv

    htop
    wget
    unzip
    rsync
    gnupg
    killall
    tmux
    httpie

    ffmpeg
    texlive.combined.scheme-full
    python3Packages.pygments

    terraform
    google-cloud-sdk
  ] ++ (if host == "kedar" then [
    google-chrome
    lm_sensors
    bintools
    racket
    perf
    # (import ./vivado { inherit pkgs; })
  ] else if host == "sarang" then [
    swiftlint
    highlight
    ngrok
    nodePackages.serve
    # nodePackages.webtorrent-cli
    yt-dlp
  ] else []);

  home.file."Library/Application Support/Code/User/settings.json" = {
    source = ./vscode-settings.json;
    enable = isDarwin;
  };

  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    source = ./ghostty-config;
    enable = isDarwin;
  };

  home.file.".config/fish/fish_variables" = {
    source = ./fish_variables;
    enable = isDarwin;
  };

  home.sessionVariables = {
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
    LIBRARY_PATH = let
      libs = [pkgs.libiconv];
    in ''${lib.makeLibraryPath libs}''${LIBRARY_PATH:+:$LIBRARY_PATH}'';
    SCCACHE_SERVER_PORT = "4227";
  };
}
