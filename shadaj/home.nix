{ config, pkgs, ... }:

with pkgs; # bring all of Nixpkgs into scope

let
  unstable = import <nixos-unstable> {
    config = { allowUnfree = true; };
  };

  device = ( import ./device.secret.nix );
  javaPkg = adoptopenjdk-hotspot-bin-16;
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

  nixpkgs.config.allowUnfree = true;

  programs.fish = {
    enable = true;
    promptInit = (builtins.readFile ./fish-prompt.fish);
    shellInit = ''
      set PATH $PATH ~/bin
      set PATH $PATH $HOME/.cargo/bin
      alias nix-fish="nix-shell --run fish";
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
    ] ++ (if device.name == "bihag" then [ ".DS_Store" ] else []);

    lfs = {
      enable = true;
    };

    extraConfig = {
      pull = {
        rebase = "false";
      };
    };
  };

  programs.vscode = {
    enable = (device.name == "kedar");
    package = vscode;
    extensions = with unstable.vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
      scalameta.metals
      ms-vsliveshare.vsliveshare
      matklad.rust-analyzer
      ms-vscode.cpptools
    ];
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  programs.java.enable = true;
  programs.java.package = javaPkg;

  home.packages = [
    (if device.name == "kedar" then nodejs-14_x else nodejs-16_x)

    git

    (sbt.override {
      jre = javaPkg;
    })

    rustup
    clang
    automake
    cmake

    ruby
    go

    htop
    wget
    unzip
    rsync
    httpie
    killall

    octave
    texlive.combined.scheme-full
    ffmpeg
  ] ++ (if device.name == "kedar" then [
    google-chrome
    lm_sensors
    ( import ./vivado )
  ] else [
    gnupg
    highlight
    ngrok
  ]);

  home.sessionVariables = {
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
  };
}
