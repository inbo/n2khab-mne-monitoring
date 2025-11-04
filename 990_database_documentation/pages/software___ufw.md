alias:: ufw, firewall

- https://wiki.archlinux.org/title/Uncomplicated_Firewall
- ```
  ufw default deny
  ufw allow <ssh-port>/tcp
  ufw limit <ssh-port>/tcp # rate limit: 6 attempts / 30 sec
  ufw allow <port>/tcp
  ufw logging off
  ufw status
  ufw enable
  ```
- > ufw status
  ```
  To                         Action      From
  --                         ------      ----
  22                         DENY        Anywhere
  <ssh-port>/tcp                   LIMIT       Anywhere
  <port>/tcp                   ALLOW       Anywhere
  22 (v6)                    DENY        Anywhere (v6)
  <ssh-port>/tcp (v6)              LIMIT       Anywhere (v6)
  <port>/tcp (v6)              ALLOW       Anywhere (v6)
  ```