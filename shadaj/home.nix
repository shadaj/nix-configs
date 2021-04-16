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
{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "shadaj";
  home.homeDirectory = "/home/shadaj";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";

  xdg.enable = true;
  xdg.mime.enable = true;
  targets.genericLinux.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.fish = {
    enable = true;
    promptInit = (builtins.readFile ./fish-prompt.fish);
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
      jre = unstable.adoptopenjdk-hotspot-bin-16;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    extensions = with unstable.pkgs.vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
      ms-toolsai.jupyter
      scalameta.metals
      ms-vsliveshare.vsliveshare
    ];
  };


  programs.direnv.enable = true;
  programs.direnv.enableNixDirenvIntegration = true;

  home.packages = [
    pkgs.google-chrome
    pkgs.nodejs-12_x
    pkgs.fortune
    pkgs.cowsay
    pkgs.git
    unstable.adoptopenjdk-hotspot-bin-16
    pkgs.sbtJDK16
    pkgs.htop
    pkgs.lm_sensors
    ( import ./vivado )
  ];

  home.sessionVariables = {
    JAVA_HOME = "${unstable.adoptopenjdk-hotspot-bin-16}";
  };
}
