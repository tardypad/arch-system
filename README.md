# Arch system

Personal [Arch Linux](https://www.archlinux.org/) system management

- bin: scripts to manage system and packages
- builds: custom packages builds
- doc: general documentation about repository
- setup: scripts to setup system
- utilities: helper scripts to manage the repository


## Scripts

Most scripts rely on the following packages

| Name        | Purpose                          | Source                                                                            | Version                                                                                                     |
|-------------|----------------------------------|-----------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| fakeroot    | Simulate superuser privileges    | [Debian](http://debian.backend.mirrors.debian.org/debian/pool/main/f/fakeroot)    | [1.31](http://debian.backend.mirrors.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.31.orig.tar.gz)      |
| pacman      | package manager                  | [Archlinux](https://git.archlinux.org/pacman.git)                                 | [6.0.2](https://git.archlinux.org/pacman.git/tag/?h=v6.0.2)                                                 |



## Setup

```shell
# from Live USB
curl -s https://git.sr.ht/~tardypad/arch-system/blob/master/setup/setup-1.sh | sh | tee install.log

# after first login as user
# with HDD=hdd1 or HDD=hdd2
curl -s https://git.sr.ht/~tardypad/arch-system/blob/master/setup/setup-2.sh -o setup-2.sh
sh setup-2.sh $HDD
```


## Builds

Builds are run within a pre setup LXC container named "arch-builds".
The build container can be created via the "utilities/setup-build-container" script.
