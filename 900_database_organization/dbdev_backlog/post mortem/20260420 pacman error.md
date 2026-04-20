---
aliases:
  - the broken mirror
  - pacman could not read db 
  - pacman damaged tar archive 
  - pacman bad header checksum 
  - pacman unknown key
tags:
  - server
  - pacman
  - error
  - archlinux
started: 2026-04-20
finished: 2026-04-20
execution:
  - FM
status: true
---

## symptoms

pacman would not update, no matter what. `pacman -Sy` or `pacman -Syu` would all fail:

```
error: could not read db 'core' (Damaged tar archive (bad header checksum))
error: could not read db 'extra' (Damaged tar archive (bad header checksum))
```

## libarchive?
Found similar issue due to change in libarchive logic - look and behold, last week was a [libarchive update](https://archlinux.org/packages/core/x86_64/libarchive/).

Figured out that there is no `wget` installed for terminal downloads (okay, so what, ... `*hesitation*`).
- downloaded libarchive package
- scp'd it to the server, 
- and installed with `pacman -U libarchive-3.8.7-1-x86_64.pkg.tar.zst`

This turned out not to be the root cause.

## corrupt database?
Found another potential issue with the pacman databases; turns out they can be purged:
```sh
rm -f /var/lib/pacman/sync/*.db
```
... but error persists.

(*edit: I should rather have moved them instead of deleting.*)

## keys up to date?
Initially, the error also threw an invalid key (background: all packages are signed). 
Time for a keyring update? Indeed!

Again, applied strategy "download + scp + `pacman -U archlinux-keyring-20260409-1-any.pkg.tar.zst`".

To no avail:
the `key` detail of the issue is gone, but the core issue remains.

## package cache?
[This](https://forum.manjaro.org/t/issues-after-an-improper-shutdown/177604) post turned out to contain a good, stepwise approach.

Next potential cause was the package cache, which was supposed to be emptied and reset.
(Since my `/var/cache/pacman/pkg/` has `pacman -U`'d me out of a lot of trouble in the past, I rather copied it to a backup space first.)

`pacman -Scc` cleared the cache, but not the familiar error on `pacman -Syyuu`.

## the broken mirror
[The good lead](https://bbs.archlinux.org/viewtopic.php?pid=1805153#p1805153) came from a user named "Inspector parrot", who casually mentioned to a new user that one should that
> mirrorlist is up to date

The mirrorlist [had updates, indeed](https://archlinux.org/packages/core/any/pacman-mirrorlist/).

So, why not?
```sh
pacman -U pacman-mirrorlist-20260406-1-any.pkg.tar.zst 
cd /etc/pacman.d
mv mirrorlist mirrorlist.bak
mv mirrorlist.pacnew mirrorlist
nvim mirrorlist # comment in some proximal mirrors
pacman -Syyuu
```

And that finally solved it.

The previously selected mirror is online, and I cannot infer the cause on their side.

> [!important] Mirrors are important
> Good reminder to keep track of your linux distribution's mirrors and make sure they are reliable and trustworthy.

(Good also that arch implements package signing to trigger errors when things are strange.)