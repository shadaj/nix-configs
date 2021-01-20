{ config, pkgs, ... }:
let
  vscode-overlay = self: super:
  {
    vscode-extensions = self.lib.recursiveUpdate super.vscode-extensions {
      ms-vsliveshare.vsliveshare = (pkgs.callPackage (import ./vscode-live-share) {});
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
    promptInit = ''
      function fish_greeting
        fortune -s computers science riddles | cowsay -f dragon
      end

      function fish_prompt --description 'Write out the prompt'
        if not set -q __fish_git_prompt_show_informative_status
          set -g __fish_git_prompt_show_informative_status 1
        end
        if not set -q __fish_git_prompt_hide_untrackedfiles
          set -g __fish_git_prompt_hide_untrackedfiles 1
        end

        if not set -q __fish_git_prompt_color_branch
          set -g __fish_git_prompt_color_branch magenta --bold
        end
        if not set -q __fish_git_prompt_showupstream
          set -g __fish_git_prompt_showupstream "informative"
        end
        if not set -q __fish_git_prompt_char_upstream_ahead
          set -g __fish_git_prompt_char_upstream_ahead "↑"
        end
        if not set -q __fish_git_prompt_char_upstream_behind
          set -g __fish_git_prompt_char_upstream_behind "↓"
        end
        if not set -q __fish_git_prompt_char_upstream_prefix
          set -g __fish_git_prompt_char_upstream_prefix ""
        end

        if not set -q __fish_git_prompt_char_stagedstate
          set -g __fish_git_prompt_char_stagedstate "●"
        end
        if not set -q __fish_git_prompt_char_dirtystate
          set -g __fish_git_prompt_char_dirtystate "✚"
        end
        if not set -q __fish_git_prompt_char_untrackedfiles
          set -g __fish_git_prompt_char_untrackedfiles "…"
        end
        if not set -q __fish_git_prompt_char_conflictedstate
          set -g __fish_git_prompt_char_conflictedstate "✖"
        end
        if not set -q __fish_git_prompt_char_cleanstate
          set -g __fish_git_prompt_char_cleanstate "✔"
        end

        if not set -q __fish_git_prompt_color_dirtystate
          set -g __fish_git_prompt_color_dirtystate blue
        end
        if not set -q __fish_git_prompt_color_stagedstate
          set -g __fish_git_prompt_color_stagedstate yellow
        end
        if not set -q __fish_git_prompt_color_invalidstate
          set -g __fish_git_prompt_color_invalidstate red
        end
        if not set -q __fish_git_prompt_color_untrackedfiles
          set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
        end
        if not set -q __fish_git_prompt_color_cleanstate
          set -g __fish_git_prompt_color_cleanstate green --bold
        end

        set -l last_status $status

        if not set -q __fish_prompt_normal
            set -g __fish_prompt_normal (set_color normal)
        end

        set -l color_cwd
        set -l prefix
        set -l suffix
        switch $USER
          case root toor
            if set -q fish_color_cwd_root
              set color_cwd $fish_color_cwd_root
            else
              set color_cwd $fish_color_cwd
            end
            set suffix '#'
          case '*'
            set color_cwd $fish_color_cwd
            set suffix '$'
        end

        # PWD
        set_color $color_cwd
        echo -n (prompt_pwd)
        set_color normal

        printf '%s ' (__fish_vcs_prompt)

        if not test $last_status -eq 0
          set_color $fish_color_error
        end

        echo -n "$suffix "

        set_color normal
      end
    '';
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

    extraConfig = {
      pull = {
        rebase = "false";
      };
    };
  };

  nixpkgs.config.packageOverrides = pkgs: rec {
    sbtJDK14 = pkgs.sbt.override {
      jre = pkgs.jdk14;
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    extensions = with unstable.pkgs.vscode-extensions; [
      ms-python.vscode-pylance
      ms-python.python
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
    pkgs.gnumake
    pkgs.jdk14
    pkgs.sbtJDK14
    pkgs.clang
    pkgs.python3
    pkgs.htop
    pkgs.lm_sensors
    ( import ./vivado )
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk14}";
  };
}
