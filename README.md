# Arch Linux ARM Build Scripts (Raspberry Pi 4)

This repository provides scripts for building an up-to-date Arch Linux ARM rootfs from official sources for Raspberry Pi 4. The build process leverages an OCI container (Docker container) for a clean and isolated environment, and utilizes emulation to execute aarch64 binaries within the chroot during the bootstrapping process.

## Features

* Builds a minimal Arch Linux ARM rootfs for Raspberry Pi 4.
* [Compatible with BCM2711 C0 stepping](https://archlinuxarm.org/forum/viewtopic.php?f=67&t=15422).
* Creates two users `root` and `alarm`, with their username as passwords (same as official rootfs).
* Configures DHCP for automatic network configuration.
* Enables SSH server for remote access.
* Addresses known build issues:
  * [Fixes untrusted GPG builder key issue](https://archlinuxarm.org/forum/viewtopic.php?f=15&t=16701) with `allow-weak-key-signatures` option in `/etc/pacman.d/gnupg/gpg.conf`.
  * [Resolves `mkinitcpio` failure due to unsupported `kms` parameter](https://archlinuxarm.org/forum/viewtopic.php?f=15&t=16672&start=60) by removing `kms` from `/etc/mkinitcpio.conf`.
* Utilizes official Arch Linux ARM packages for a reliable build.
* Dockerfile simplifies building the containerized build environment even on non-Arch systems.
* Employs qemu-user-static and qemu-user-static-binfmt to execute aarch64 binaries within the chroot environment, enabling building on non-aarch64 platforms.

## Prerequisites

* Docker installed and running on your system.
* (Optional) Partitioned SD card. You can mount the root SD card partition directly into the container.

## Usage

1. **Clone this Repository:**

    ```bash
    git clone https://github.com/kleest/alarm-builder-rpi4.git
    ```

2. **Build the Docker Image:**

    This creates a Docker image named `alarm-builder` containing the build scripts and tools.

    ```bash
    cd alarm-builder-rpi4
    docker build . -f Dockerfile -t alarm-builder
    ```

3. **Run the Build Script:**

    The build script resides within the container image. This command starts the container, executes the script, and mounts the output directory to `/build/chroot` within the container.

    ```bash
    docker run --rm -it --privileged -v /mnt/tmp-root:/build/chroot alarm-builder
    ```

    **Important Flags:**

    * `--privileged`: Grants elevated permissions required for running `pacstrap` and `mount` inside the container.
    * `-v /mnt/tmp-root:/build/chroot`: Mounts the host directory `/mnt/tmp-root` (replace with your desired location) to `/build/chroot` within the container. This is the output directory where the rootfs will be generated.

4. **Using the Rootfs:**

    After a successful build, you find the generated rootfs in the mounted directory. If you mounted the SD card root partition into the container, you need to follow the rest of the official instructions on how to copy data from `/boot` to the correct partition. Afterwards you can directly boot the SD card.

    *Important*: Do not apply the modifications to `/etc/fstab` that are outlined in the official instructions.

## Additional Notes and References

* Refer to the Arch Linux ARM documentation [https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4) for details on SD card setup and rootfs installation.
