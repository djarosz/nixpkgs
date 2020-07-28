self: super:
  
let
  callPackage = super.lib.callPackageWith self;
in
{
  mfcj200lpr = callPackage ./pkgs/mfcj200lpr.nix { };
  mfcj200cupswrapper = callPackage ./pkgs/mfcj200cupswrapper.nix { };
}
