#!/usr/bin/env bash
set -euo pipefail

# === Paths ===
WORK="$HOME/goinfre"
VMDK="$WORK/p3/ubuntu-22.04-server-cloudimg.vmdk"
VMNAME="Server"
VDI="$WORK/VirtualBox VMs/${VMNAME}.vdi"
CONF_SEED="../config"
SEED="$WORK/p3/seed.iso"

# Host bridged adapter name
BRIDGE_ADAPTER="enp0s31f6"

# === Step 1: Clone VMDK to VDI to avoid UUID conflicts ===
echo "[1/5] Cloning VMDK → VDI..."
VBoxManage closemedium disk "/home/hlachkar/goinfre/VirtualBox VMs/Server.vdi" --delete 2>/dev/null || true
VBoxManage closemedium disk "$VMDK" 2>/dev/null || true
rm -f "$VDI"
VBoxManage clonemedium disk "$VMDK" "$VDI" --format VDI

# === Step 2: Create VM ===
echo "[2/5] Creating VM..."
VBoxManage unregistervm "$VMNAME" --delete 2>/dev/null || true
VBoxManage createvm --name "$VMNAME" --ostype Ubuntu_64 --basefolder "$WORK/VirtualBox VMs" --register

# === Step 3: Attach storage ===
echo "[3/5] Attaching storage..."
VBoxManage storagectl "$VMNAME" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "$VMNAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VDI"

# === Step 4: Configure VM ===
echo "[4/5] Configuring VM..."
VBoxManage modifyvm "$VMNAME" --memory 4096 --cpus 4
VBoxManage modifyvm "$VMNAME" --nic1 hostonly --hostonlyadapter1 vboxnet0 --cableconnected1 on
VBoxManage modifyvm "$VMNAME" --nic2 bridged --bridgeadapter2 "$BRIDGE_ADAPTER" --cableconnected2 on
VBoxManage modifyvm "$VMNAME" --boot1 disk --boot2 dvd --boot3 none --boot4 none

echo "[5/5] Creating seed.iso with updated network-config..."

if [[ ! -f "$CONF_SEED/user-data" ]] || [[ ! -f "$CONF_SEED/meta-data" ]] || [[ ! -f "$CONF_SEED/network-config" ]]; then
    echo "❌ Missing one or more config files in $CONF_SEED (need user-data, meta-data, network-config)"
    exit 1
fi
rm -f "$SEED"
(
    cd "$CONF_SEED"
    xorriso -as mkisofs -o "$SEED" -V cidata -J -r user-data meta-data network-config
)

VBoxManage storagectl "$VMNAME" --name "IDE Controller" --add ide
VBoxManage storageattach "$VMNAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$SEED"

echo "✅ VM '$VMNAME' created successfully."
echo "💡 Start it with: VBoxManage startvm \"$VMNAME\" --type headless"

