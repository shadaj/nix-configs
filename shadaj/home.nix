{ config, pkgs, unstable, host, isDarwin, ... }:

with pkgs; # bring all of Nixpkgs into scope

let
  javaPkg = openjdk19;
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
      set PATH /Applications/Tailscale.app/Contents/MacOS $PATH
    '' else '''');
  };

  programs.git = {
    enable = true;
    userName = "Shadaj Laddad";
    userEmail = "shadaj@users.noreply.github.com";
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

    extraConfig = {
      pull = {
        rebase = "false";
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.vscode = {
    enable = (host == "kedar");
    package = vscode;
    extensions = with unstable.vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
      ms-toolsai.jupyter
      ms-vscode.cpptools
      golang.go
      bbenoist.nix
      tomoki1207.pdf
    ];
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
    nodejs-18_x

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
    racket
    octave
    python3
    protobuf

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

    htop
    wget
    unzip
    rsync
    gnupg
    killall
    tmux
    httpie
    sccache

    ffmpeg
    texlive.combined.scheme-full
  ] ++ (if host == "kedar" then [
    google-chrome
    lm_sensors
    bintools
    # (import ./vivado { inherit pkgs; })
  ] else if host == "sarang" then [
    highlight
    ngrok
    nodePackages.serve
    nodePackages.webtorrent-cli
    unstable.yt-dlp
  ] else []);

  home.sessionVariables = {
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
    LIBRARY_PATH = ''${lib.makeLibraryPath [pkgs.libiconv]}''${LIBRARY_PATH:+:$LIBRARY_PATH}'';
  } // (if host == "sarang" then {
    NIX_CC_WRAPPER_TARGET_HOST_aarch64_apple_darwin = "1";
    NIX_CFLAGS_COMPILE =
      "-iframework ${darwin.apple_sdk.frameworks.CoreFoundation}/Library/Frameworks " +
      "-iframework ${darwin.apple_sdk.frameworks.CoreServices}/Library/Frameworks " +
      "-iframework ${darwin.apple_sdk.frameworks.Security}/Library/Frameworks " +
      "-iframework ${darwin.apple_sdk.frameworks.SystemConfiguration}/Library/Frameworks";
  } else {});
}
