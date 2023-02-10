{
  description = "A very basic flake";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

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
          nativeBuildInputs = [ pkgs."llvmPackages_${toString llvmVersion}".lld ];
          buildPhase = ''
            $CXX -flto=thin -c foo.cc
            $CXX -flto=thin -c main.cc
            export NIX_DEBUG=1
            $CXX -v -fuse-ld=lld -flto=thin -rdynamic -o exe main.o foo.o -lc++abi
          '';
          installPhase = "install -D -t $out/bin exe";
        };

      packages.x86_64-linux.default =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
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
            $CXX -rdynamic -o exe main.o foo.o
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