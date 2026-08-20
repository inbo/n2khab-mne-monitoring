---
tags:
  - server
  - software
  - update
  - updates
---
The server runs on [[server/os|arch linux]] and software is managed via the arch package management tools.

## update procedure
To run an update, execute the following steps.
+ connect to the server via `ssh`
+ launch a named [GNU Screen](https://wiki.archlinux.org/title/GNU_Screen) session with `screen -S update` ("update" is the name of the session)
+ change to elevated privileges
+ check packages to update with `pacman -Sy && pacman -Qu`
+ update
+ reboot
+ check if everything works

If `ssh` connection is lost in the process, re-connect and continue with `screen -x update`.