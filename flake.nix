{
  description = "system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:msteen/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, home-manager, vscode-server }: {
    darwinConfigurations."sarang" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./sarang/darwin-configuration.nix ];
      inputs = { inherit darwin nixpkgs; };
    };

    homeConfigurations."shadaj@sarang" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config = { allowUnfree = true; };
      };

      system = "aarch64-darwin";

      username = "shadaj";
      homeDirectory = "/Users/shadaj";
      stateVersion = "21.05";

      configuration = _: {
        imports = [
          ./shadaj/home.nix
        ];
      };

      extraSpecialArgs = {
        unstable = import nixpkgs-unstable {
          system = "aarch64-darwin";
          config = { allowUnfree = true; };
        };

        host = "sarang";
      };
    };

    homeConfigurations."shadaj@kedar" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = { allowUnfree = true; };
      };

      system = "x86_64-linux";

      username = "shadaj";
      homeDirectory = "/home/shadaj";
      stateVersion = "20.09";

      configuration = _: {
        imports = [
          vscode-server.nixosModules.home
          ./shadaj/home.nix
        ];
      };

      extraSpecialArgs = {
        unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config = { allowUnfree = true; };
        };

        host = "kedar";
      };
    };
  };
}
