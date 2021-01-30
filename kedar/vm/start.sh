#!/bin/sh
# Helpful to read output when debugging
# set -x

nvidia-smi -pm 0

# Stop display manager
# systemctl stop x11vnc.service
systemctl stop display-manager.service
## Uncomment the following line if you use GDM
pkill -x gdm-x-session

systemctl stop ethminer.service

# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind
echo 0 > /sys/class/vtconsole/vtcon1/bind

# Unbind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind

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

# modprobe -r snd_hda_intel

virsh nodedev-list

# Unbind the GPU from display driver
virsh nodedev-detach pci_0000_09_00_0
virsh nodedev-detach pci_0000_09_00_1
virsh nodedev-detach pci_0000_09_00_2
virsh nodedev-detach pci_0000_09_00_3

virsh nodedev-detach pci_0000_0b_00_4

# Load VFIO Kernel Module
modprobe vfio-pci
modprobe vfio_iommu_type1
modprobe vfio
