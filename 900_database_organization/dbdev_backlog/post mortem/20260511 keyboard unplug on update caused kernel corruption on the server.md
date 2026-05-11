---
aliases:
  - falks keyboard cable falk-up
  - kernel corruption after incomplete update
tags:
  - mkinitcpio
  - chroot
  - server
started: 2026-05-11
finished: 2026-05-11
execution:
  - FM
status: true
---

![[attachments/keyboard_connector_20260511114418.jpg]]

# timeline
+ [11:00] #FM attempted an update (regular procedure)
+ [11:00] accidentally disconnected keyboard chord 
	+ with magnetic adapter (generally good to avoid strain on the usb-c connector)
	+ but this time it ripped off just the wrong moment
+ [11:08] notification via fieldwork chat
+ [11:10-11:34] restoration via linode recovery shell
+ [11:34] server back up and running
+ [*ex post*] tested using GNU Screen

# lessons learned

+ **start using GNU Screen**
	+ [GNU Screen](https://wiki.archlinux.org/title/GNU_Screen)
	+ [(brief introduction)](https://medium.com/@yiskylee/gnu-screen-and-tmux-which-should-you-choose-de325d32fc2a)
```
screen -S update # start a named session
# screen -ls # list existing sessions
# screen -x update # resume the "update" session
```
+ always pull dumps prior to updates
+ next time: create extra dump just before update (minimize potential loss)
+ better keep the keyboard steady and the ssh stable
+ there is a rescue mode to access the server
+ "chrooting" saved my day

# restoration
+ first attempt: backup image
	+ in hope of saving the data at crash time, create a backup image of the node 
	+ *failed*; probably due to the corruption
+ server offers a `rescue` shell!
![[attachments/server_rescue_shell_20260511115040.jpg]]
+ selecting the (corruped) systems for mount on startup as `/dev/sda`
+ mount corrupted drive to `/mnt` (*cf.* [trick here](https://superuser.com/q/165116))
```sh
mount /dev/sda /mnt
mount --bind /proc /mnt/proc 
mount --bind /dev /mnt/dev 
mount --bind /sys /mnt/sys
```
+ `chroot` to the system (*cf.* [arch wiki: chroot](https://wiki.archlinux.org/title/Chroot))
```sh
chroot /mnt
```
+ `mkinitcpio` to complete building the kernel image (*cf.* [arch wiki: mkinitcpio](https://wiki.archlinux.org/title/Mkinitcpio))
```sh
mkinitcpio -P
```
+ re-build [grub config](https://wiki.archlinux.org/title/GRUB#Generate_the_main_configuration_file) (because that seemed to hang on startup)
```sh
grub-mkconfig -o /boot/grub/grub.cfg
```
+ reboot
```sh
reboot  
```

-> server up and working again.