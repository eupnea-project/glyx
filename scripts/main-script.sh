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
  # determine pcie addresses
  echo "detecting hardware"
}

detach_hardware() {
  # detach hardware
  echo "detaching hardware"
}

start_qemu() {
  qemu-system-x86_64 -m 2048 -nic user -boot d -cdrom ./alpine-minirootfs-3.19.0-x86_64/opt/Fedora-KDE-Live-x86_64-39-1.5.iso -display sdl -enable-kvm
}

reattach_hardware() {
  # reattach hardware
  echo "reattaching hardware"
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
  mount_iso_storage
  read_iso_storage
  detect_hardware
  detach_hardware
  start_qemu
  reattach_hardware
  install_kaboot
  install_packages
  reboot_device
}

main