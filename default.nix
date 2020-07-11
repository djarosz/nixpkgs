{ system ? builtins.currentSystem }:

let
  pkgs = import <nixpkgs> { inherit system; };
  
  callPackage = pkgs.lib.callPackageWith (pkgs // self);
  
  self = {
    mfcj200lpr = callPackage ./pkgs/mfcj200lpr { };
    mfcj200cupswrapper = callPackage ./pkgs/mfcj200cupswrapper { };
  };
in
self

