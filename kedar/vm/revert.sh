#!/bin/sh
# set -x

# Unload VFIO-PCI Kernel Driver
modprobe -r vfio-pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

# Re-Bind GPU to Nvidia Driver
virsh nodedev-reattach pci_0000_0a_00_3
virsh nodedev-reattach pci_0000_0a_00_2
virsh nodedev-reattach pci_0000_0a_00_1
virsh nodedev-reattach pci_0000_0a_00_0

virsh nodedev-reattach pci_0000_0c_00_4

# Rebind VT consoles
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

nvidia-xconfig --query-gpu-info > /dev/null 2>&1
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia
modprobe ipmi_devintf
modprobe ipmi_msghandler
modprobe snd_hda_intel

# Restart Display Manager
systemctl start display-manager.service

systemctl start ethminer.service

nvidia-smi -pm 1
