# NixOS on Raspberry Pi

My personal notes on how to setup NixOS on Raspberry Pi

Model:
 - Pi 3B+

# Using prebuilt image available on Hydra

The latest image is on Hydra:

[sd-image](https://hydra.nixos.org/job/nixos/release-20.09/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image)

If the image have extension .img.zst , then you need to uncompress it.

```bash
unzstd sd-image.img.zst
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

# Building using Github Action

We can leverage Github Action to build our image. We can reuse existing action to setup qemu-user-static and then build and deploy the image as workflow artifact. You can then download the artifact from Github, which is the zipped sd-image.img file.

I already setup a workflow manual dispatch Github Action in this repo, so to build your own customized NixOS raspi image, follow this steps.

1. Fork the repo so you can build your own custom image
2. Create your build/deployment environment. 

From your repo settings page, click the Environments menu. Click New environment. Give it a name other than `default`. Define environment secrets called `CONFIGURATION_NIX`. The content should be your sd Image Nix recipe (not your future NixOS configuration.nix). See the sample template file in: [configuration.default.sdImage.nix](configuration.default.sdImage.nix) or [configuration.sdImage.nix](configuration.sdImage.nix)

3. Run your workflow

In the Actions page, select `nix-build-on-demand-docker` action and then click `Run workflow`. You will be given an option to specify the environment name. Fill in the name of the environment you set up in step 2. Click Run workflow. If you use `default` environment name, it will build [configuration.default.sdImage.nix](configuration.default.sdImage.nix) as the recipe.

4. Wait for it to finish

5. Retrieve the artifact

When the build finish, in your action job page, there will be Artifacts panel with artifacts named `sd-image.img`. Click on it and it will download a zipped file. Extract the zipfile and it will contain the image, as `.img` or `.img.zstd` depending on your config you provided.

# Building on x86/64 machine

The reason you may want to build your image yourself is because you want to store the initial config as an image.
For example, it may include your own initial service like SSH, or network configuration (static IP, WIFI password, etc).

You need NixOS or just Nix package manager

You need QEMU ARM if you only have Nix. 

## Example in Ubuntu

For example to use it in Ubuntu:

*notes* for some reason, sd image build failed to build if we are using latest Linux kernel (5.4 currently). So, we need to use latest QEMU user-static that is available on debian sid (currently) or QEMU user-static version 5.x.x. Adding the repository is beyond the scope of this README and please do so if you understand that it is coming from and unstable apt repo.

```bash
sudo apt -y install qemu-user-static
```

Since we are going to run aarch64 binaries inside our x86_64 box, we need qemu-user-static to run aarch64 executable transparently.
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

## Example in NixOS

If you have NixOS, adding binfmt support is super easy.

Just add the binfmt support in your `/etc/nixos/configuration.nix`

```
# add this line inside the nix function
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
```

Then, `nixos-rebuild switch` your configuration and your NixOS is ready to be used for cross-compilation.

The rest of the steps are the same with the Ubuntu example above after installing `qemu-user-static`

# Building on ARM machine with Linux

Same as above, but you don't need to install QEMU. You just need Nix or NixOS.

The build command:

```
# notice that we don't need to specify --argstr system aarch64-linux
nix-build '<nixpkgs/nixos>' -A config.system.build.sdImage -I nixos-config=./configuration.sdImage.nix \
  --option sandbox false
```

# Building using Docker

Theoritically we can also build cross-platform using Docker container. 
Normally this is used to build cross platform docker images, but we can also use it to build cross-platform in the host.

You need docker or podman installed as a prerequisite.

First we need to register the binfmt from a docker image. We use this repository: [https://hub.docker.com/r/multiarch/qemu-user-static](https://hub.docker.com/r/multiarch/qemu-user-static).

```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

The trick works like this. Normally the image above is used to register qemu-user-static interpreter inside the container. Since `/proc/sys/fs/binfmt_misc` are the same in the host and container, if the image were run using `--privileged`, then the binfmt in the host are also registered with the binaries inside the docker image. So basically the docker image serves as a convenient packaging library for qemu-user-static.

According to the documentation, the `-p yes` flag tells the image to register the binfmt and persists it even if the container exits. So the interpreter are also available in the host kernel. However you can't check the interpreter version directly in the host, since the binaries don't exists in the host (but in the image above). To check the version, the author uses the convention like this:

```bash
# supply the platform as image tag, e.g. aarch64
docker run --rm --privileged multiarch/qemu-user-static:aarch64 /usr/bin/qemu-aarch64-static --version
```

Now your kernel can execute aarch64 binaries and you can cross-compile. There rest of the steps are the same.

# Reference

- [NixOS on ARM installation notes](https://nixos.wiki/wiki/NixOS_on_ARM#Installation)
- [NixOS Pi 3 installation notes](https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_3#Board-specific_installation_notes)