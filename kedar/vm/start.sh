#!/bin/sh
set -x

TPM_UUID="05776f22-15b8-4e4f-ae00-047d63bfd6fc"
TPM_BACKUP="/home/shadaj/vm/swtpm/$TPM_UUID/tpm2-00.permall"
TPM_STATE="/var/lib/libvirt/swtpm/$TPM_UUID/tpm2/tpm2-00.permall"

mkdir -p "$(dirname "$TPM_STATE")"
if [ -f "$TPM_BACKUP" ]; then
  cp "$TPM_BACKUP" "$TPM_STATE"
fi

nvidia-smi -pm 0

# Stop display manager
systemctl stop moonshine.service
systemctl stop display-manager.service
pkill -x gdm-x-session

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
# echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Avoid a Race condition by waiting 2 seconds. This can be calibrated to be shorter or longer if required for your system
sleep 5

# Unload all Nvidia drivers
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
# UVM's device major can change on reload. NixOS's udev mknod rules do not
# replace existing nodes, so remove them only after a successful unload.
if modprobe -r nvidia_uvm; then
  udevadm settle || exit 1
  rm -f /dev/nvidia-uvm /dev/nvidia-uvm-tools
else
  exit 1
fi
modprobe -r nvidia
modprobe -r i2c_nvidia_gpu
# Looks like these might need to be unloaded on Ryzen Systems. Not sure yet.
modprobe -r ipmi_devintf
modprobe -r ipmi_msghandler

virsh nodedev-list

# Unbind the GPU from display driver
virsh nodedev-detach pci_0000_0a_00_0
virsh nodedev-detach pci_0000_0a_00_1
virsh nodedev-detach pci_0000_0a_00_2
virsh nodedev-detach pci_0000_0a_00_3

virsh nodedev-detach pci_0000_0c_00_4

# Load VFIO Kernel Module
modprobe vfio-pci
modprobe vfio_iommu_type1
modprobe vfio
