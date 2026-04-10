---
aliases:
  - linux keyring
tags:
  - keyring
started: 2026-04-09
finished: 2026-04-09
execution:
  - FM
status: true
---

```sh
keyring --list-backends
```
... was missing `keyring.backends.SecretService.Keyring`

ultimately solved by installing gnome-keyring and (!) REBOOT
```sh
sudo pacman -Sy libsecret gnome-keyring seahorse
# yay -Sy dssd
```
*seahorse is a useful GUI tool to manage keyrings.*

testing:
```r
options(keyring_backend = "secret_service")
library("keyring")
keyring_list()
keyring_create(keyring = "test", password = "")
keyring_lock(keyring = "test")
keyring_delete(keyring = "test")
```