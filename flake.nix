{
  description = "system configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    secrets.url = "github:input-output-hk/empty-flake?rev=2040a05b67bf9a669ce17eca56beb14b4206a99a";

    vscode-server.url = "github:msteen/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, darwin, home-manager, secrets, vscode-server }: {
    nixosConfigurations.kedar = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit secrets;
        inputs = self.inputs;

        unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "nodejs-16.20.2"
            ];
          };
        };
      };
      modules = [ ./kedar/configuration.nix ];
    };

    darwinConfigurations."sarang" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./sarang/darwin-configuration.nix ];
      inputs = {
        inherit darwin nixpkgs;
        inputs = self.inputs;
        host = "sarang";
      };
    };

    homeConfigurations."shadaj@sarang" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "aarch64-darwin";
        config = { allowUnfree = true; };
      };

      modules = [
        ./shadaj/home.nix
        {
          home = {
            username = "shadaj";
            homeDirectory = "/Users/shadaj";
            stateVersion = "21.05";
          };
        }
      ];

      extraSpecialArgs = {
        unstable = import nixpkgs-unstable {
          system = "aarch64-darwin";
          config = { allowUnfree = true; };
        };

        host = "sarang";
        isDarwin = true;
      };
    };

    homeConfigurations."shadaj@kedar" = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config = { allowUnfree = true; };
      };

      modules = [
        vscode-server.nixosModules.home
        ./shadaj/home.nix
        {
          home = {
            username = "shadaj";
            homeDirectory = "/home/shadaj";
            stateVersion = "20.09";
          };
        }
      ];

      extraSpecialArgs = {
        unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config = { allowUnfree = true; };
        };

        host = "kedar";
        isDarwin = false;
      };
    };
  };
}
