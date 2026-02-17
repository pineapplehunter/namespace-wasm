{ stdenv, lib }:

stdenv.mkDerivation {
  name = "sample-wasm";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./main.c
      ./Makefile
    ];
  };

  makeFlags = ["PREFIX=$(out)"];
}
