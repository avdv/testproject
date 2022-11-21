{
  description = "A very basic flake";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-22.05;

  outputs = { self, nixpkgs }:
    let newShell = pkgs:
      let
        inherit (pkgs) pkgsStatic;
        stdenvStatic = pkgsStatic.llvmPackages_11.libcxxStdenv;
        mkShell = pkgsStatic.mkShell.override { stdenv = stdenvStatic; };
      in
      mkShell {
        packages = with pkgs; [ which ];
      };
    in
    {
      packages.x86_64-darwin.default =
        let
          pkgs = import nixpkgs {
            system = "x86_64-darwin";
          };
          inherit (pkgs) pkgsStatic;
          llvmVersion = import ./llvmVersion.nix;
          stdenvStatic = pkgsStatic."llvmPackages_${toString llvmVersion}".libcxxStdenv;
        in
        stdenvStatic.mkDerivation {
          name = "llvmcompile";
          src = ./.;
          buildPhase = ''
            $CXX -c foo.cc
            $CXX -c main.cc
            $CXX -v -rdynamic -o exe main.o foo.o
          '';
          installPhase = "install -D -t $out/bin exe";
        };

      devShells.x86_64-linux.default =
        let pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        in
        newShell pkgs;

      devShells.x86_64-darwin.default =
        let pkgs = import nixpkgs {
          system = "x86_64-darwin";
        };
        in
        newShell pkgs;
    };
}
