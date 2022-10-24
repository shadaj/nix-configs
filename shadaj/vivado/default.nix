# based on https://github.com/lukaslaobeyer/nix-fpgapkgs/tree/master/pkgs/vivado

{pkgs, ...}:

with pkgs; # bring all of Nixpkgs into scope

stdenv.mkDerivation rec {
  name = "vivado";
  version = "2021.2";

  buildInputs = [ patchelf procps ncurses makeWrapper zlib unzip ];
  
  builder = ./builder.sh;
  inherit ncurses;

  src = fetchurl {
    url = file://Xilinx_Unified_2021.2_1021_0703.tar.gz;
    sha256 = "10v59sngh0zncv0kfp8p68lp8c9jl7xlyq6b892qc0y9mrlkarp2";
  };

  libPath = lib.makeLibraryPath
    [ stdenv.cc.cc ncurses zlib xorg.libX11 xorg.libXrender xorg.libxcb xorg.libXext xorg.libXtst xorg.libXi glib
      freetype gtk2 ];
  
  meta = {
    description = "Xilinx Vivado";
    homepage = "https://www.xilinx.com/products/design-tools/vivado.html";
    license = lib.licenses.unfree;
  };
}
