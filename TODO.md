Periodic:
- Check packages new versions and releases  
  compare new default configuration files with our own
- Update packages list with the `update_lists` utility script
- Check for modified package files using `pacman -Qkk`

Cleaning:

Bugs:

Testing:

Improvements:
- list reason for the installation of the package  
  such as `acpi_call # needed for TLP battery threshold`  

New Features:
- make a script to better report modified package files
- make a script to build the packages for AUR and tardypad

Research:
- [aconfmgr](https://github.com/CyberShadow/aconfmgr) configuration manager  
  maybe to replace our system-config package
- [lostfiles](https://github.com/graysky2/lostfiles) identify files not owned by a package
- [arch-audit](https://github.com/ilpianista/arch-audit) list security vulnerabilities
