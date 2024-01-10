#!/bin/bash

# GLOBAL VARS:
iso_storage_mnt_point="/mnt/iso-storage/"

# import functions file
source functions.sh

# initialize crash handler
trap crash_handler ERR
trap crash_handler SIGINT
trap crash_handler SIGTERM

# exit on error
set -e
set -o pipefail

read_iso_storage() {
  # find and mount the second partition of the currently booted device
  # get the currently mounted device without partition number
  currently_mounted_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed 's/.$//')
  # mount the second partition of the currently booted device
  mount "${currently_mounted_device}2" /mnt/iso-storage || error_and_reboot "Failed mounting the iso storage"

  files=()
  if [ -d "$iso_storage_mnt_point" ]; then
      # Loop through files in the directory and add them to the array
      for file in "$iso_storage_mnt_point"/*; do
          # Add only filenames (not directories) to the array
          if [ -f "$file" ]; then
              # check if file is an iso
              if [[ "$file" != *.iso ]]; then
                  continue
              fi
              files+=("$(basename "$file")")
          fi
      done
  else
      error_and_reboot "Iso storage directory not found?"
  fi

  # if more than one file is found, let the user choose one
  if [ ${#files[@]} -gt 1 ]; then
      # whiptail expects the array to be formatted like this: "tag" "item" "tag" "item" ...
      # We dont have item descriptions, only tags -> add empty string items to list as descriptions
      for ((i = ${#files[@]} - 1; i >= 0; i--)); do
        files=("${files[@]:0:i+1}" "" "${files[@]:i+1}")
      done

      iso_file_name=$(whiptail --noitem --nocancel --title "Choose an ISO file" --menu "Choose an ISO file" 20 40 10 "${files[@]}" 3>&1 1>&2 2>&3)

  else # if only one file is found, use it
      iso_file_name="${files[0]}"
  fi
}

detect_hardware() {
  # determine if iommu is supported
  if dmesg | grep -i "IOMMU enabled"; then
      # check that only one gpu is present
      if [ $(lspci | grep -c "VGA compatible controller") -gt 1 ]; then
          error_and_reboot "More than one GPU detected"
      fi
      gpu_address=$(lspci | grep "VGA compatible controller" | cut -d' ' -f 1)
      # check that address is not empty
      if [ -z "$gpu_address" ]; then
          error_and_reboot "GPU address not found"
      fi
  else
      # prompt user to accept or reboot on cancel
      if ! whiptail --title "Warning" --yesno "IOMMU is disabled. Performance will suffer. Continue anyways?" 10 40; then
          reboot_device
      fi
      gpu_address="iommu_disabled"
  fi

  # calculate the amount of memory to allocate to the VM
  total_mem=$(cat /proc/meminfo | grep "MemTotal" | awk '{print $2}')
  vm_memory=$((total_mem * 80 / 100))
}

run_virtual_machine() {
  if [ "$gpu_address" = "iommu_disabled" ]; then
    qemu-system-x86_64 -nodefaults -enable-kvm -cpu host,kvm=off -display none -vga none -nographic -nic user -boot d \
    -m "${vm_memory}kb" \
    -cdrom "${iso_storage_mnt_point}${iso_file_name}"
  else
    qemu-system-x86_64 -nodefaults -enable-kvm -cpu host,kvm=off -display none -vga none -nographic -nic user -boot d \
    -m "${vm_memory}kb" \
    -device vfio-pci,host=$gpu_address,multifunction=on \
    -cdrom "${iso_storage_mnt_point}${iso_file_name}"
  fi
}

install_kaboot() {
  # install kaboot
  echo "installing kaboot"
}

install_packages() {
  # install packages
  echo "installing packages"
}

main () {
  read_iso_storage
  prepare_target_storage
  detect_hardware
  run_virtual_machine
  install_kaboot
  install_packages
  reboot_device
}

main