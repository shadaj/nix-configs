# based on https://github.com/lukaslaobeyer/nix-fpgapkgs/tree/master/pkgs/vivado

with import <nixpkgs> {}; # bring all of Nixpkgs into scope

stdenv.mkDerivation rec {
  name = "vivado-2019.1";

  buildInputs = [ patchelf procps ncurses makeWrapper zlib unzip ];
  
  builder = ./builder.sh;
  inherit ncurses;

  src = fetchurl {
    url = file://Xilinx_Vivado_SDK_2019.1_0524_1430.tar.gz;
    sha256 = "0a60fqyrfj0d8wcjlqi2mmi320r3xilndppk16isnddwihd0iczj";
  };

  libPath = stdenv.lib.makeLibraryPath
    [ stdenv.cc.cc ncurses zlib xorg.libX11 xorg.libXrender xorg.libxcb xorg.libXext xorg.libXtst xorg.libXi glib
      freetype gtk2 ];
  
  meta = {
    description = "Xilinx Vivado";
    homepage = "https://www.xilinx.com/products/design-tools/vivado.html";
    license = stdenv.lib.licenses.unfree;
  };
}
