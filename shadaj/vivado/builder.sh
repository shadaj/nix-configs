set -e

source $stdenv/setup

export LD_LIBRARY_PATH=$libPath:$LD_LIBRARY_PATH

echo "unpacking $src..."
mkdir extracted
tar xzf $src -C extracted --strip-components=1

echo "running installer..."

cat <<EOF > install_config.txt
Edition=Vivado HL WebPACK
Destination=$out/opt
Modules=Software Development Kit (SDK):0,DocNav:0,Kintex UltraScale:0,Zynq-7000:1,System Generator for DSP:0,Artix-7:1,Kintex-7:0
InstallOptions=Acquire or Manage a License Key:0,Enable WebTalk for Vivado to send usage statistics to Xilinx (Always enabled for WebPACK license):1
CreateProgramGroupShortcuts=0
ProgramGroupFolder=Xilinx Design Tools
CreateShortcutsForAllUsers=0
CreateDesktopShortcuts=0
CreateFileAssociation=0
EnableDiskUsageOptimization=1
EOF

patchShebangs extracted

patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
         extracted/tps/lnx64/jre9.0.4/bin/java
#         extracted/tps/lnx64/jre/bin/java

mkdir -p $out/opt

sed -i -- 's|/bin/rm|rm|g' extracted/xsetup

# The installer will be killed as soon as it says that post install tasks have failed.
# This is required because it tries to run the unpatched scripts to check if the installation
# has succeeded. However, these scripts will fail because they have not been patched yet,
# and the installer will proceed to delete the installation if not killed.
(extracted/xsetup --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA --batch Install --config install_config.txt || true) | while read line
do
    [[ "${line}" == *"Execution of Pre/Post Installation Tasks Failed"* ]] && echo "killing installer!" && ((pkill -9 -f "extracted/tps/lnx64/jre/bin/java") || true)
    echo ${line}
done

rm -rf extracted

# Patch installed files
patchShebangs $out/opt/Vivado/2019.1/bin
# patchShebangs $out/opt/SDK/2019.1/bin
patchShebangs $out/opt/Vivado/2019.1/lnx64/tools/gcc/libexec/gcc/x86_64-unknown-linux-gnu/4.6.3/install-tools/
echo "Shebangs patched"

# Hack around lack of libtinfo in NixOS
ln -s $ncurses/lib/libncursesw.so.6 $out/opt/Vivado/2019.1/lib/lnx64.o/libtinfo.so.5
# ln -s $ncurses/lib/libncursesw.so.6 $out/opt/SDK/2019.1/lib/lnx64.o/libtinfo.so.5

# Patch ELFs
for f in $out/opt/Vivado/2019.1/bin/unwrapped/lnx64.o/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $f || true
done

# for f in $out/opt/SDK/2019.1/bin/unwrapped/lnx64.o/*
# do
#     patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $f || true
# done

for f in $out/opt/Vivado/2019.1/lnx64/tools/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $f || true
done

for f in $out/opt/Vivado/2019.1/lnx64/tools/clang/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $f || true
done

for f in $out/opt/Vivado/2019.1/lnx64/tools/clang-3.9/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

for f in $out/opt/Vivado/2019.1/lnx64/tools/clang-3.9-csynth/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

for f in $out/opt/Vivado/2019.1/lnx64/tools/gcc/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

for f in $out/opt/Vivado/2019.1/lnx64/tools/dot/bin/*
do
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $(readlink -f $f) || true
done

patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/Vivado/2019.1/lnx64/tools/gcc/libexec/gcc/x86_64-unknown-linux-gnu/4.6.3/install-tools/fixincl

# patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/SDK/2019.1/eclipse/lnx64.o/eclipse

# patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/SDK/2019.1/tps/lnx64/jre/bin/java
patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/opt/Vivado/2019.1/tps/lnx64/jre9.0.4/bin/java

echo "ELFs patched"

vivado_bins="apcc diffbd hw_server hw_serverpv loader numxscreens sdx_server
svf_utility symbol_server tcflog updatemem vcse_server vivado vivado_hls vlm
wbtcv xar xcpp xcrg xelab xlicdiag xrcserver xsc xsdb xsim xtclsh xvc_pcie xvhdl
xvlog"

mkdir $out/bin

for vivado_bin in $vivado_bins;
do
    wrapProgram $out/opt/Vivado/2019.1/bin/$vivado_bin --prefix LD_LIBRARY_PATH : "$libPath"
    sed -i -- "s|\`basename \"\$0\"\`|$vivado_bin|g" $out/opt/Vivado/2019.1/bin/.$vivado_bin-wrapped
    ln -s $out/opt/Vivado/2019.1/bin/$vivado_bin $out/bin/$vivado_bin
done

# wrapProgram $out/opt/SDK/2019.1/bin/xsdk --prefix LD_LIBRARY_PATH : "$libPath"
# sed -i -- 's|`basename "\$0"`|xsdk|g' $out/opt/SDK/2019.1/bin/.xsdk-wrapped
# ln -s $out/opt/SDK/2019.1/bin/xsdk $out/bin/xsdk

# wrapProgram $out/opt/Vivado/2019.1/bin/vivado --prefix LD_LIBRARY_PATH : "$libPath"
# wrapProgram $out/opt/Vivado/2019.1/bin/vivado --prefix LD_LIBRARY_PATH : "$libPath"
wrapProgram $out/opt/Vivado/2019.1/tps/lnx64/jre9.0.4/bin/java --prefix LD_LIBRARY_PATH : "$libPath"
# wrapProgram $out/opt/SDK/2019.1/eclipse/lnx64.o/eclipse --prefix LD_LIBRARY_PATH : "$libPath"
# wrapProgram $out/opt/SDK/2019.1/tps/lnx64/jre9.0.4/bin/java --prefix LD_LIBRARY_PATH : "$libPath"

# # wrapProgram on its own will not work because of the way the Vivado script runs ./launch
# # Therefore, we need Even More Patches...
# sed -i -- 's|`basename "\$0"`|vivado|g' $out/opt/Vivado/2019.1/bin/.vivado-wrapped
# sed -i -- 's|`basename "\$0"`|xsdk|g' $out/opt/SDK/2019.1/bin/.xsdk-wrapped
# sed -i -- 's|`basename "\$0"`|xsdk|g' $out/opt/SDK/2019.1/bin/.xsdk-wrapped

# Add vivado and xsdk to bin folder
# ln -s $out/opt/Vivado/2019.1/bin/vivado $out/bin/vivado

# Manually GCC mkheaders
$out/opt/Vivado/2019.1/lnx64/tools/gcc/libexec/gcc/x86_64-unknown-linux-gnu/4.6.3/install-tools/mkheaders $out/opt/Vivado/2019.1/lnx64/tools/gcc

cp $out/opt/Vivado/2019.1/lnx64/tools/gcc/include/c++/4.6.3/parallel/*.h $out/opt/Vivado/2019.1/lnx64/tools/gcc/include/c++/4.6.3/
cp $out/opt/Vivado/2019.1/lnx64/tools/gcc/include/c++/4.6.3/parallel/*.h $out/opt/Vivado/2019.1/lnx64/tools/gcc/include/
