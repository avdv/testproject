let pkgs = import <nixpkgs> {};
in
  pkgs.mkShell {
    name = "foo";
    packages = [ pkgs.cowsay ];
  }
