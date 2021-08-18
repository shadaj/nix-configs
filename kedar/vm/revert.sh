#!/bin/sh

# Unload VFIO-PCI Kernel Driver
modprobe -r vfio
modprobe -r vfio_iommu_type1
modprobe -r vfio-pci

# Re-Bind GPU to Nvidia Driver
virsh nodedev-reattach pci_0000_0c_00_4

virsh nodedev-reattach pci_0000_0a_00_3
virsh nodedev-reattach pci_0000_0a_00_2
virsh nodedev-reattach pci_0000_0a_00_1
virsh nodedev-reattach pci_0000_0a_00_0

modprobe ipmi_msghandler
modprobe ipmi_devintf
modprobe nvidia
modprobe nvidia_uvm
modprobe nvidia_modeset
modprobe nvidia_drm

nvidia-xconfig --query-gpu-info > /dev/null 2>&1
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

# Rebind VT consoles
echo 1 > /sys/class/vtconsole/vtcon0/bind
echo 1 > /sys/class/vtconsole/vtcon1/bind

# Restart Display Manager
systemctl start display-manager.service
systemctl start ethminer.service

nvidia-smi -pm 1

cp /var/lib/libvirt/swtpm/05776f22-15b8-4e4f-ae00-047d63bfd6fc/tpm2/tpm2-00.permall /home/shadaj/vm/swtpm/05776f22-15b8-4e4f-ae00-047d63bfd6fc/tpm2-00.permall
