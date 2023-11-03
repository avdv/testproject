{ script, pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [ (pkgs.writers.writeBashBin "ci.nix" "exec $BASH ${script}") pkgs.cowsay ];
}
