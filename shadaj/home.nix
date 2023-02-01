{ config, pkgs, unstable, host, ... }:

with pkgs; # bring all of Nixpkgs into scope

let
  javaPkg = openjdk17;
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
    '' + (if host == "kedar" then '''' else ''
      alias matlab="/Applications/MATLAB_R2019b.app/bin/matlab -nodesktop"
      set PATH /Applications/Tailscale.app/Contents/MacOS $PATH
    '');
  };

  programs.git = {
    enable = true;
    userName = "Shadaj Laddad";
    userEmail = "shadaj@users.noreply.github.com";
    ignores = [
      "shell.nix" ".direnv/" ".envrc" ".venv/"
      "metals.sbt" ".bloop/" ".bsp/" ".metals/"
      ".vsls.json"
      ".vscode/"
    ] ++ (if host == "sarang" then [ ".DS_Store" ] else []);

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
      scalameta.metals
      scala-lang.scala
      matklad.rust-analyzer
      ms-vscode.cpptools
      golang.go
      bbenoist.nix
      tomoki1207.pdf

      zhuangtongfa.material-theme
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
    nodejs-16_x

    git

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

    (pkgs.clang.overrideAttrs (attrs: {
      # lower priority than binutils
      meta.priority = pkgs.binutils.meta.priority + 1;
    }))
    automake
    cmake
    bintools

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
  ] ++ (if host == "kedar" then [
    google-chrome
    lm_sensors
    (import ./vivado { inherit pkgs; })
  ] else [
    highlight
    ngrok
    nodePackages.serve
    nodePackages.webtorrent-cli
    unstable.youtube-dl
  ]);

  home.sessionVariables = {
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
  };
}
