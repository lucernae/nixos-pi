# NixOS on Raspberry Pi

My personal notes on how to setup NixOS on Raspberry Pi

Model:
 - Pi 3B+

# Using prebuilt image available on Hydra

The latest image is on Hydra:

[sd-image](https://hydra.nixos.org/job/nixos/release-20.09/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image)

If the image have extension .img.zst , then you need to uncompress it.

```bash
unzstd sd-image.img.zst sd-image.img
```

Flash the image to your sd card using dd. Follow the instruction in NixOS [wiki](https://nixos.wiki/wiki/NixOS_on_ARM#Installation_steps) that links to the raspberry pi original docs.

With this setup, you have a bare minimum image that you can access via HDMI and keyboard.

Further configuration are done via `/etc/nixos/configuration.nix` (the image is a NixOS).
Create the file and fill in your configuration.
Here's some example from mine: [configuration.nix](configuration.nix)

Build the configuration

```
nixos-rebuild test -p test
```

This will build the configuration but not set it as the default boot. You can try if everything works okay and then reboot. From the boot menu, choose this profile to test if everything works after reboot. If you do nothing in the boot menu, it will choose your last default profile instead of this `test` profile.
It is also possible to create different nixos-config file and build it accordingly to test several config:

```
nixos-rebuild test -p test-1 -I nixos-config=./test.nix
```


# Building on x86/64 machine

The reason you may want to build your image yourself is because you want to store the initial config as an image.
For example, it may include your own initial service like SSH, or network configuration (static IP, WIFI password, etc).

You need NixOS or just Nix package manager

You need QEMU ARM if you only have Nix. For example to use it in Ubuntu:

```bash
sudo apt -y install qemu qemu-kvm qemu-system-arm qemu-user qemu-user-binfmt
```

Since we are going to run aarch64 binaries inside our x86_64 box, we need qemu-user-binfmt to run aarch64 executable transparently.
Check that `binfmt_misc` now support this:

```bash
ls -l /proc/sys/fs/binfmt_misc | grep aarch64
```

If it returns something (`qemu-aarch64`), you are on the right track.

Add the following line to `/etc/nix/nix.conf`: `extra-platforms = aarch64-linux` . If the file doesn't exist, create it.

Create a base nix file for SD Card image build. Typically this contains some config for basic setup that you want to make it work right after flashing the image.
For example, public SSH keys, or static IP address settings, or WI-FI password, list of system packages and services, etc.

The nix file must import the SD Image packages

```nix
{ config, pkgs, lib, ... }:
{

  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
  ];
  
  # Do not compress the image as we want to use it straight away
  sdImage.compressImage = false;

  # The rest of user config goes here
}
```

See example in: [configuration.sdImage.nix](configuration.sdImage.nix)

Then build the image:

```
nix-build '<nixpkgs/nixos>' -A config.system.build.sdImage -I nixos-config=./configuration.sdImage.nix \
  --argstr system aarch64-linux \
  --option sandbox false
```

When the image finally built (normally you don't want to compress it), you can flash it to SD card like in the above instructions.
Boot your pi and access it (via Keyboard + HDMI, or over SSH), then you need to `fix` your `/etc/nixos/configuration.nix`.
The nixos config that you made for building the image is for installation image, meanwhile you may have different nixos config after that.
Typical configuration includes deleting the import lines for sd-image (So you don't rebuild image again), specifying basic fs mount (or additionally swap).

# Building on ARM machine with Linux

Same as above, but you don't need to install QEMU. You just need Nix or NixOS.

The build command:

```
nix-build '<nixpkgs/nixos>' -A config.system.build.sdImage -I nixos-config=./configuration.sdImage.nix \
  --option sandbox false
```

# Reference

- [NixOS on ARM installation notes](https://nixos.wiki/wiki/NixOS_on_ARM#Installation)
- [NixOS Pi 3 installation notes](https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_3#Board-specific_installation_notes)