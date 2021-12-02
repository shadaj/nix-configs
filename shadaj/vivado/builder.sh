set -e
shopt -s globstar

source $stdenv/setup

export LD_LIBRARY_PATH=$libPath:$LD_LIBRARY_PATH

export VIDADO_VERSION="2021.2"

echo "unpacking $src..."
mkdir extracted
tar xzf $src -C extracted --strip-components=1

echo "running installer..."

cat <<EOF > install_config.txt
Edition=Vivado ML Standard
Product=Vivado
Destination=$out/opt
Modules=Virtex UltraScale+ HBM:0,DocNav:0,Kintex UltraScale:0,Artix UltraScale+:0,Spartan-7:0,Artix-7:1,Virtex UltraScale+:0,Vitis Model Composer(Xilinx Toolbox for MATLAB and Simulink. Includes the functionality of System Generator for DSP):0,Zynq UltraScale+ MPSoC:0,Zynq-7000:1,Kintex-7:0,Install Devices for Kria SOMs and Starter Kits:0,Kintex UltraScale+:0
InstallOptions=Acquire or Manage a License Key:0
CreateProgramGroupShortcuts=0
ProgramGroupFolder=Xilinx Design Tools
CreateShortcutsForAllUsers=0
CreateDesktopShortcuts=0
CreateFileAssociation=0
EnableDiskUsageOptimization=1
EOF

patchShebangs extracted

for f in extracted/tps/lnx64/**/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

mkdir -p $out/opt

sed -i -- 's|/bin/rm|rm|g' extracted/xsetup

# The installer will be killed as soon as it says that post install tasks have failed.
# This is required because it tries to run the unpatched scripts to check if the installation
# has succeeded. However, these scripts will fail because they have not been patched yet,
# and the installer will proceed to delete the installation if not killed.
extracted/xsetup --agree XilinxEULA,3rdPartyEULA --batch Install --config install_config.txt || true

rm -rf extracted

# Patch installed files
patchShebangs $out/opt/Vivado/$VIDADO_VERSION/bin
for f in $out/opt/Vivado/$VIDADO_VERSION/lnx64/**/install-tools/*
do
    patchShebangs $f
done
echo "Shebangs patched"

# Hack around lack of libtinfo in NixOS
ln -s $ncurses/lib/libncursesw.so.6 $out/opt/Vivado/$VIDADO_VERSION/lib/lnx64.o/libtinfo.so.5

# Patch ELFs
for f in $out/opt/Vivado/$VIDADO_VERSION/bin/unwrapped/lnx64.o/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $f || true
done

for f in $out/opt/Vivado/$VIDADO_VERSION/**/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

for f in $out/opt/Vivado/$VIDADO_VERSION/lnx64/**/install-tools/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

echo "ELFs patched"

vivado_bins="bootgen hw_server program_ftdi tcflog wbtcv xrcserver xvc_pcie
bootgen_utility hw_serverpv xar xrt_server xvhdl
cdoutil xcd xsc xvlog cdoutil_int loader updatemem xcrg xsdb
cs_server manage_ipcache svf_utility vivado xelab xsim
diffbd me_ca_udm_dbg symbol_server vlm xlicdiag xtclsh"

mkdir $out/bin

for vivado_bin in $vivado_bins;
do
    wrapProgram $out/opt/Vivado/$VIDADO_VERSION/bin/$vivado_bin --prefix LD_LIBRARY_PATH : "$libPath"
    sed -i -- "s|\`basename \"\$0\"\`|$vivado_bin|g" $out/opt/Vivado/$VIDADO_VERSION/bin/.$vivado_bin-wrapped
    ln -s $out/opt/Vivado/$VIDADO_VERSION/bin/$vivado_bin $out/bin/$vivado_bin
done

for java_bin in $out/opt/Vivado/$VIDADO_VERSION/**/bin/java
do
    wrapProgram $java_bin --prefix LD_LIBRARY_PATH : "$libPath"
done
