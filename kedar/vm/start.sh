#!/bin/sh

mkdir -p /var/lib/libvirt/swtpm/05776f22-15b8-4e4f-ae00-047d63bfd6fc/tpm2
cp /home/shadaj/vm/swtpm/05776f22-15b8-4e4f-ae00-047d63bfd6fc/tpm2-00.permall /var/lib/libvirt/swtpm/05776f22-15b8-4e4f-ae00-047d63bfd6fc/tpm2/tpm2-00.permall

nvidia-smi -pm 0

# Stop display manager
systemctl stop display-manager.service
pkill -x gdm-x-session

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/unbind

# Avoid a Race condition by waiting 2 seconds. This can be calibrated to be shorter or longer if required for your system
sleep 5

# Unload all Nvidia drivers
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r nvidia_uvm
modprobe -r nvidia
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
