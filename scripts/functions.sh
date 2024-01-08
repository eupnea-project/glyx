error_and_reboot() {
  # display error message to user
  whiptail --title "Error" --msgbox "$1" 10 40
  reboot_device
}

crash_handler() {
  # display the last message from the log file
  whiptail --title "Error" --msgbox "An unexpected error occurred" 10 40
  reboot_device
}

reboot_device() {
  # display reboot message to user
  whiptail --title "Reboot" --msgbox "Rebooting..." 10 40
  # reboot the device after user pressed OK
  # TODO: Uncomment next line
  # reboot
}