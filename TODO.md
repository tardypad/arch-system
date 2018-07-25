Periodic:
- Check packages new versions and releases  
  compare new default configuration files with our own
- Update packages list with the `update_lists` utility script
- Check for modified package files with the `TBD` utility script
- Check for files not belonging to any package with the `TBD` utility script

Cleaning:

Bugs:

Testing:

Improvements:

New Features:
- make a script to report modified package files
- make a script to report files not belonging to any package  
  [lostfiles](https://github.com/graysky2/lostfiles)
- make a script to launch all steps for a new system setup:
  * create user
  * setup aur/tardypad repositories
  * setup aurutils
  * build packages from aur/tardypad lists
  * install all packages from lists

Research:
- [aconfmgr](https://github.com/CyberShadow/aconfmgr) configuration manager  
  maybe to replace our system-config package
- [arch-audit](https://github.com/ilpianista/arch-audit) list security vulnerabilities
