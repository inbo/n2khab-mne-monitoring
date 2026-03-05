---
aliases:
  - ssh
---

## general

- via [[software/openssh|openssh]]
- key only
- non-standard port
- no root login
- add new users `cat ~/.ssh/ssh_key.pub` to `~/.ssh/authorized_keys` of the unprivileged login user
- mind [[software/ufw|firewall]]

## configure ssh:
> vim /etc/ssh/sshd_config
```
Port <ssh-port>
ListenAddress <host>
PermitRootLogin no
PasswordAuthentication no
```

example for connection:
```
ssh -p <port> <system_user>@<host>
```

might be useful:
- `scp` to copy files there and back again, e.g. for [[database/backups|backups]] ([*cf.*](https://wiki.archlinux.org/title/SCP_and_SFTP))
- `sshfs` to mount remote file systems ([*cf.*](https://wiki.archlinux.org/title/SSHFS))
