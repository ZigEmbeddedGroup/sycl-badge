{pkgs ? import <nixpkgs> {}}: let
  vhs = import ./vhs.nix;
in
  pkgs.mkShell {
    nativeBuildInputs = [
      pkgs.openocd
      pkgs.gdb
      pkgs.zig_0_11_0
      pkgs.dfu-util
      pkgs.gcc-arm-embedded
    ];
    buildInputs = [];
    shellHook = ''
      # help
    '';
  }
