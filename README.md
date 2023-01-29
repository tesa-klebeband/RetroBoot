# RetroBoot
A bootloader capable of loading 16-bit binary files from a MBR partition

## Features
* Supports FAT16 partitions
* Ability to chainload FAT16 partions
* Load and execute binary files to custom locations
* Very small and fast

## Building
### Requirements
* Make
* nasm
* GCC
* Qemu - only for testing purposes

To build RetroBoot run `make` in the root of this project.
## Using RetroBoot
### Installing
The easiest way of installing RetroBoot is to write the produced image to your drive using:

`dd if=retroboot.img of=/dev/sdX`

Make sure you replace `/dev/sdX` with your drive (e.g. /dev/sda). This will delete everything on the drive, so make sure you make a backup of all your data.
Copy your config files (*.rbo) and your binary files to the first partition of your drive.
### Creating configurations
#### Loading and executing files
To create a config file run:

`build/mkconfig boot.rbo "BOOT    BIN" 0 31744 512 128`

This will create boot.rbo that when loaded will load 512 bytes BOOT.BIN to segment 0 and offset 0x7c00 and sets the drive number to 0x80.
* Replace the first argument with the config name
* Replace the second argument with the filename you want to load (8.3 Filename)
* Replace the third argument with the load segment (decimal, I will fix that later)
* Replace the fourth argument with the load offset (decimal, 0x7c00 -> 31744)
* Replace the fifth argument with the bytes to actually load (decimal)
* Replace the sixth argumaent with the drive number to set once the file is executed (decimal, 0x81 = second HDD, 0x80 -> 128)
#### Chainloading the first partition
`build/mkconfig boot.rbo`
* Replace the first argument with the config filename
## LICENSE
All files within this repo are released under the GNU GPL V3 License as per the LICENSE file stored in the root of this repo.
