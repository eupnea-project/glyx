#!/bin/bash

# import functions file
source functions.sh

# initialize crash handler
trap crash_handler ERR
trap crash_handler SIGINT
trap crash_handler SIGTERM

# exit on error
set -e
set -o pipefail

mount_iso_storage() {
  # find and mount the second partition of the currently booted device
  # get the currently mounted device without partition number
  currently_mounted_device=$(mount | grep ' / ' | cut -d' ' -f 1 | sed 's/.$//')
  # mount the second partition of the currently booted device
  mount "${currently_mounted_device}2" /mnt/iso-storage || error_and_reboot "Failed mounting the iso storage"
}

read_iso_storage() {
  # Navigate to the directory
  directory="/mnt/iso-storage"

  # Store filenames in an array
  files=()

  # Check if the directory exists
  if [ -d "$directory" ]; then
      # Loop through files in the directory and add them to the array
      for file in "$directory"/*; do
          # Add only filenames (not directories) to the array
          if [ -f "$file" ]; then
              files+=("$(basename "$file")")
          fi
      done

      # Print the list of filenames
      printf '%s\n' "${files[@]}"
  else
      error_and_reboot "Directory not found."
  fi
}

main () {
  mount_iso_storage
  read_iso_storage
  detach_hardware
  start_qemu
  reattach_hardware
  install_kaboot
  install_packages
  reboot_device
}

main