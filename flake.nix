{
  description = "A very basic flake";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
    let
      newShell = pkgs:
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
          llvmVersion = import ./llvmVersion.nix;
          addEmptyGccEh = final: prev: {
            empty-gcc-eh = prev.runCommand "empty-gcc-eh" { } ''
              mkdir -p $out/lib
              ${prev.binutils-unwrapped}/bin/ar r $out/lib/libgcc_eh.a
            '';
            "llvmPackages_${toString llvmVersion}" = prev.lib.attrsets.updateManyAttrsByPath [
              {
                path = [ "llvmPackages_${toString llvmVersion}" "libcxxabi" ];
                update = (old: old.overrideAttrs
                  (_: {
                    buildInputs = old.libcxxabi.buildInputs + [ final.empty-gcc-eh ];
                  }));
              }
            ]
              prev;
          };
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [ addEmptyGccEh ];
          };
          inherit (pkgs) pkgsStatic;
          stdenvStatic = pkgsStatic."llvmPackages_${toString llvmVersion}".libcxxStdenv;
          empty-gcc-eh = pkgs.runCommand "empty-gcc-eh" { } ''
            if $CC -Wno-unused-command-line-argument -x c - -o /dev/null <<< 'int main() {}'; then
              echo "linking succeeded; please remove empty-gcc-eh workaround" >&2
              exit 3
            fi
            mkdir -p $out/lib
            ${pkgs.binutils-unwrapped}/bin/ar r $out/lib/libgcc_eh.a
          '';
        in
        stdenvStatic.mkDerivation {
          name = "llvmcompile";
          src = ./.;
          buildPhase = ''
            export NIX_LDFLAGS="$NIX_LDFLAGS -L${empty-gcc-eh}/lib"
            $CXX -c foo.cc
            $CXX -c main.cc
            $CXX -rdynamic -o exe main.o foo.o
          '';
          installPhase = "install -D -t $out/bin exe";
        };

      devShells.x86_64-linux.default =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
          };
        in
        newShell pkgs;

      devShells.x86_64-darwin.default =
        let
          pkgs = import nixpkgs {
            system = "x86_64-darwin";
          };
        in
        newShell pkgs;
    };
}
