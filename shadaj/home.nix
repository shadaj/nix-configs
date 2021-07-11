{ config, pkgs, ... }:

with pkgs; # bring all of Nixpkgs into scope

let
  vscode-overlay = self: super:
  {
    vscode-extensions = self.lib.recursiveUpdate super.vscode-extensions {
      # ms-vsliveshare.vsliveshare = (pkgs.callPackage (import ./vscode-live-share) {});
      ms-toolsai.jupyter = pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "jupyter";
          publisher = "ms-toolsai";
          version = "2020.12.414227025";
          sha256 = "1zv5p37qsmp2ycdaizb987b3jw45604vakasrggqk36wkhb4bn1v";
        };
      };
    };
  };

  unstable = import <nixos-unstable> {
    config = { allowUnfree = true; };
    overlays = [ vscode-overlay ];
  };
in
let
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

  targets = if device.name == "kedar" then {
    genericLinux.enable = true;
  } else {};

  nixpkgs.config.allowUnfree = true;

  programs.fish = {
    enable = true;
    promptInit = (builtins.readFile ./fish-prompt.fish);
    shellInit = ''
      set PATH $PATH ~/bin
      set PATH $PATH $HOME/.cargo/bin
      alias nix-fish="nix-shell --run fish";
    '' + (if device.name == "kedar" then ''
      export NIX_PATH="$HOME/.nix-defexpr/channels:$NIX_PATH"
    '' else ''
      alias matlab="/Applications/MATLAB_R2019b.app/bin/matlab -nodesktop"
    '');
  };

  programs.git = {
    enable = true;
    userName = "Shadaj Laddad";
    userEmail = "shadaj@users.noreply.github.com";
    ignores = [
      "shell.nix" ".direnv/" ".envrc" ".venv/"
      "project/metals.sbt" ".bloop/" ".bsp/" ".metals/"
      ".vsls.json"
    ];

    lfs = {
      enable = true;
    };

    extraConfig = {
      pull = {
        rebase = "false";
      };
    };
  };

  nixpkgs.config.packageOverrides = pkgs: rec {
    sbtJDK16 = sbt.override {
      jre = javaPkg;
    };

    yosys = pkgs.yosys.overrideAttrs(old: {
      preBuild = old.preBuild + ''
        echo 'ENABLE_NDEBUG := 1' >> Makefile.conf
        cat Makefile.conf
      '';
    });

    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };

    symbiflow-arch-defs-patched = nur.repos.mcaju.symbiflow-arch-defs.overrideAttrs(old: {
      installPhase = old.installPhase + ''
        sed -i 's/\[ -z $VPR_OPTIONS \]/[[ -z $VPR_OPTIONS ]]/g' $out/bin/vpr_common
      '';
    });
  };

  programs.vscode = {
    enable = (device.name == "kedar");
    package = vscode;
    extensions = with vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
      ms-toolsai.jupyter
      scalameta.metals
      ms-vsliveshare.vsliveshare
      matklad.rust-analyzer
    ];
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  home.packages = [
    (if device.name == "kedar" then nodejs-14_x else nodejs-16_x)

    git

    javaPkg
    pkgs.sbtJDK16

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

    octave
    texlive.combined.scheme-full
    ffmpeg
  ] ++ (if device.name == "kedar" then [
    google-chrome
    lm_sensors
    ( import ./vivado )
    nur.repos.mcaju.prjxray-tools
    symbiflow-arch-defs-patched
  ] else [
    mosh
    gnupg
    highlight
  ]);

  home.sessionVariables = {
    JAVA_HOME = "${javaPkg}";
    OPENSSL_DIR = "${openssl.dev}";
    OPENSSL_LIB_DIR = "${openssl.out}/lib";
  };
}
