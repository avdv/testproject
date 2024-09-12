{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.05";
  };

  outputs = { self, nixpkgs }:
    let system = "x86_64-linux"; pkgs = import nixpkgs { inherit system; }; in {

      apps.x86_64-linux.dockerBuild =
        { program = "${self.packages.${system}.dockerImage}"; type = "app"; };

      packages.${system}.dockerImage =
        let
          inherit (pkgs) dockerTools;
          inherit (pkgs) bash python3 ruby;
        in
        dockerTools.streamNixShellImage {
          name = "nix-build";
          drv = pkgs.mkShell.override { stdenv = pkgs.stdenvNoCC; }
            {
              PATH = pkgs.lib.makeBinPath [ pkgs.bash pkgs.coreutils ];
              nativeBuildInputs = [ bash python3 ruby ];
            };
          tag = "latest";
        };
    };
}
