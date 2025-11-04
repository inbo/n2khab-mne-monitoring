alias:: ssh

- via [[software/openssh]]
- key only
- non-standard port
- no root login
- add new users `cat ~/.ssh/ssh_key.pub` to `~/.ssh/authorized_keys` of the unprivileged login user
- mind [firewall]([[software/ufw]])
- configure ssh:
  > vim /etc/ssh/sshd_config
  ```
  Port <ssh-port>
  ListenAddress <host>
  PermitRootLogin no
  PasswordAuthentication no
  ```
- example for connection:
  ```
  ssh -p <port> <system_user>@<host>
  ```
- might be useful:
	- `scp` to copy files there and back again, e.g. for [[database/backups]] ([*cf.*](https://wiki.archlinux.org/title/SCP_and_SFTP))
	- `sshfs` to mount remote file systems ([*cf.*](https://wiki.archlinux.org/title/SSHFS))
	-