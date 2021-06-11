{ config, pkgs, ... }:
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
let device = ( import ./device.secret.nix );
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
    '' + (if device.name == "kedar" then '''' else ''
      fenv source '$HOME/.nix-profile/etc/profile.d/nix.sh'
      source (conda info --root)/etc/fish/conf.d/conda.fish
      alias matlab="/Applications/MATLAB_R2019b.app/bin/matlab -nodesktop"
    '');

    plugins = if device.name == "kedar" then [] else [
      {
        name = "plugin-foreign-env";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-foreign-env";
          rev = "dddd9213272a0ab848d474d0cbde12ad034e65bc";
          sha256 = "00xqlyl3lffc5l0viin1nyp819wf81fncqyz87jx8ljjdhilmgbs";
        };
      }
    ];
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
    sbtJDK16 = pkgs.sbt.override {
      jre = pkgs.adoptopenjdk-hotspot-bin-16;
    };
  };

  programs.vscode = {
    enable = (device.name == "kedar");
    package = pkgs.vscode;
    extensions = with unstable.pkgs.vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
      ms-toolsai.jupyter
      scalameta.metals
      ms-vsliveshare.vsliveshare
      matklad.rust-analyzer
    ];
  };

  programs.direnv.enable = true;
  programs.direnv.enableNixDirenvIntegration = true;

  home.packages = [
    (if device.name == "kedar" then pkgs.nodejs-14_x else pkgs.nodejs-16_x)

    pkgs.git

    pkgs.adoptopenjdk-hotspot-bin-16
    pkgs.sbtJDK16

    pkgs.rustup
    pkgs.clang
    pkgs.automake
    pkgs.cmake

    pkgs.ruby
    pkgs.go

    pkgs.htop
    pkgs.wget
    pkgs.unzip
    pkgs.rsync
    pkgs.httpie

    pkgs.octave
    pkgs.texlive.combined.scheme-full
    pkgs.ffmpeg
  ] ++ (if device.name == "kedar" then [
    pkgs.google-chrome
    pkgs.lm_sensors
    ( import ./vivado )
  ] else [
    pkgs.mosh
    pkgs.gnupg
    pkgs.highlight
  ]);

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.adoptopenjdk-hotspot-bin-16}";
    OPENSSL_DIR = "${pkgs.openssl.dev}";
    OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib";
  };
}
