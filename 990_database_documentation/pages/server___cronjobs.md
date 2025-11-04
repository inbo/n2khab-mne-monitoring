alias:: cronjob, cronjobs, cron

- scheduled procedures which run automatically on the host system at a given interval
- via https://wiki.archlinux.org/title/Cron
- managed by a system process, e.g. [[software/cronie]]
	- #+begin_src sh
	  systemctl enable cronie.service
	  systemctl start cronie.service
	  #+end_src
- [[database/backups]]:
  ```sh
  12 0 * * * sh ~/backups/backup_dumpall.sh 2>&1 |tee -a ~/backups/logs/dumpall.log
  22 0 * * * sh ~/backups/backup_loceval.sh 2>&1 |tee -a ~/backups/logs/backup_loceval.log
  32 0 * * * sh ~/backups/backup_mnmgwdb.sh 2>&1 |tee -a ~/backups/logs/backup_mnmgwdb.log
  ```