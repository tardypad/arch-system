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
| fakeroot    | Simulate superuser privileges    | [Debian](http://debian.backend.mirrors.debian.org/debian/pool/main/f/fakeroot)    | [1.29](http://debian.backend.mirrors.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.29.orig.tar.gz)      |
| pacman      | package manager                  | [Archlinux](https://git.archlinux.org/pacman.git)                                 | [6.0.1](https://git.archlinux.org/pacman.git/tag/?h=v6.0.1)                                                 |


## Setup

```shell
# from Live USB
curl https://git.sr.ht/~tardypad/arch-system/blob/master/setup/setup-1.sh | sh
```
