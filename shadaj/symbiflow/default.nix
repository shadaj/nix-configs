# from https://gist.github.com/CajuM/1e435dfe783c5e136096260e152db930
{ stdenv
, fetchurl
, autoPatchelfHook
, python38
, archs ? []
}:

stdenv.mkDerivation rec {
  pname   = "symbiflow-arch-defs";
  version = "20210325-000253-1c7a3d1e";

  srcs = [
    (fetchurl {
      url = "https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/201/20210325-000253/symbiflow-arch-defs-install-1c7a3d1e.tar.xz";
      sha256 = "1l67lqxcsd61zw50s62vd38gaqgn48if273ynicyarbhj0z4vv4q";
    })

    (fetchurl {
      url = "https://storage.googleapis.com/symbiflow-arch-defs/artifacts/prod/foss-fpga-tools/symbiflow-arch-defs/continuous/install/201/20210325-000253/symbiflow-arch-defs-xc7a50t_test-1c7a3d1e.tar.xz";
      sha256 = "1rpc5gsnsg3vpjsrqvm3lfl7xqppzqdfd7r968rsc3nlcpz8gqz1";
    })
  ];

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];

  propagatedBuildInputs = [ 
    python38.pkgs.lxml
    python38.pkgs.python-constraint
  ];

  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p $out
    cp -r $PWD/bin $out

    mkdir -p $out/share/symbiflow/arch
    cp -r $PWD/share/symbiflow/{scripts,techmaps} $out/share/symbiflow/
    
    for arch in ${builtins.concatStringsSep " " archs}; do
      cp -r $PWD/share/symbiflow/arch/$arch* $out/share/symbiflow/arch/
    done
  '';

  meta = with stdenv.lib; {
    description = "Project X-Ray - Xilinx Series 7 Bitstream Documentation";
    homepage    = "https://github.com/SymbiFlow/symbiflow-arch-defs";
    license     = licenses.isc;
    platforms   = platforms.all;
  };
}