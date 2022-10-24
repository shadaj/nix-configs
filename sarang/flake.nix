{
  description = "darwin configurations";

  inputs = {
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-22.05-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
  };

  outputs = { self, darwin, nixpkgs-darwin }: {
    darwinConfigurations."sarang" = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [ ./darwin-configuration.nix ];
      inputs = {
        inherit darwin;
        nixpkgs = nixpkgs-darwin;
      };
    };
  };
}
