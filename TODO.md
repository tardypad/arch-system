# TODO

## Periodic
  - Check packages new versions and releases  
    compare new default configuration files with our own
  - Update packages list with the `update-lists` utility script
  - Check for modified package files with the `TBD` utility script
  - Check for files not belonging to any package with the `TBD` utility script

## Cleaning

## Bugs
  - system setup should ask which system-config and dotfiles-git packages to install  
    * theme (light/dark)
    * version (perso/work/...)
  - fix update-lists script to take into account new base package instead of group  
    [Arch News](https://www.archlinux.org/news/base-group-replaced-by-mandatory-base-package-manual-intervention-required/)

## Testing

## Improvements
  - system-config: split configuration per package config files
  - dotfiles-config: remove non important folders from vim plugins to decrease package size  
    (remove .git folder and only keep meaningful vim folders)  
    this will imply a small adaptation to the install-vim-plugin dotfiles setup script  
    to reclone the plugin repository when needed

## New Features
  - make a script to report modified package files
  - make a script to report files not belonging to any package  
    [lostfiles](https://github.com/graysky2/lostfiles)
  - use logrotate on sfeed feeds  
    this will imply a small adaptation to the read-news dotfiles script to ignore .gz files

## Research
  - [aconfmgr](https://github.com/CyberShadow/aconfmgr) configuration manager  
    maybe to replace our system-config package
  - [arch-audit](https://github.com/ilpianista/arch-audit) list security vulnerabilities
  - evaluate usage of meta packages as in [Michael Daffin blog](https://disconnected.systems/blog/archlinux-meta-packages/)
