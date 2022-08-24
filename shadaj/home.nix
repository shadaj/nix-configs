{ config, pkgs, ... }:

with pkgs; # bring all of Nixpkgs into scope

let
  unstable = import <nixos-unstable> {
    config = { allowUnfree = true; };
  };

  device = ( import ./device.secret.nix );
  javaPkg = openjdk17;

  nixpkgs-tars = "https://github.com/NixOS/nixpkgs/archive";
in
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "shadaj";
  home.homeDirectory = (if device.name == "kedar" then "/home/shadaj" else "/Users/shadaj");

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = (if device.name == "kedar" then "20.09" else "21.05");

  xdg = if device.name == "kedar" then {
    enable = true;
    mime.enable = true;
  } else {};

  nixpkgs.config = {
    allowUnfree = true;
  };

  imports = if device.name == "kedar" then [
    "${fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master"}/modules/vscode-server/home.nix"
  ] else [];

  programs.fish = {
    enable = true;
    interactiveShellInit = (builtins.readFile ./fish-prompt.fish);
    shellInit = ''
      set PATH ~/bin $PATH
      set PATH $HOME/.cargo/bin $PATH
      set PATH /opt/homebrew/bin $PATH
      alias nix-fish="nix-shell --run fish"
      source ~/bin/iterm2_shell_integration.fish
    '' + (if device.name == "kedar" then '''' else ''
      alias matlab="/Applications/MATLAB_R2019b.app/bin/matlab -nodesktop"
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
    ] ++ (if device.name == "sarang" then [ ".DS_Store" ] else []);

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
    enable = (device.name == "kedar");
    package = vscode;
    extensions = with unstable.vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
      (import ./jupyter.nix)
      scalameta.metals
      scala-lang.scala
      ms-vsliveshare.vsliveshare
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

  services = if device.name == "kedar" then {
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
    (pkgs.clang.overrideAttrs (attrs: {
      # lower priority than binutils
      meta.priority = pkgs.binutils.meta.priority + 1;
    }))
    automake
    cmake
    bintools

    ruby
    go
    z3

    htop
    wget
    unzip
    rsync
    gnupg
    killall
    tmux

    ffmpeg
    texlive.combined.scheme-full
  ] ++ (if device.name == "kedar" then [
    google-chrome
    lm_sensors
    ( import ./vivado )
    httpie
    coq
    racket
    octave
  ] else [
    highlight
    ngrok
    nodePackages.serve
    unstable.nodePackages.webtorrent-cli
    unstable.youtube-dl
  ]);

  home.sessionVariables = {
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
  };
}
