alias:: backups

- via [[server/cronjobs]]
- daily `scp` and distribution to
	- local drive
	- external hdd
	- [google drive](https://drive.google.com/drive/folders/1zwyNuQEPcfK_CmT4OjrBeJGH9yrTrbGN?usp=drive_link)
- > cat backup_dumpall.sh
- ```
  backup_folder="~/backups/dumps"
  
  echo ""
  echo "________________________________________________________________________________"
  echo "monthly full dumps $(date +"%Y%m%d") -> ${backup_folder}"
  
  pg_dump -U <readonly_user> -h <host> -p <port> -d loceval -N tiger -N public -c \
      > "${backup_folder}/loceval_dump_$(date +"%Y%m").sql"
  
  pg_dump -U <readonly_user> -h <host> -p <port> -d mnmgwdb -N tiger -N public -c \
      > "${backup_folder}/mnmgwdb_dump_$(date +"%Y%m").sql"
  ```
- > cat backup_loceval.sh
- ```sh
  backup_folder="~/backups/loceval/"
  
  echo ""
  echo "________________________________________________________________________________"
  echo "running backup $(date +"%Y%m%d%H%M") -> ${backup_folder}"
  
  pg_dump -U <readonly_user> -h <host> -p <port> -d loceval -N tiger -N public -c \
      | diff "${backup_folder}loceval_latest.sql" - \
      > "${backup_folder}loceval_diff_$(date +"%Y%m%d%H%M").patch"
  
  patch "${backup_folder}loceval_latest.sql" -i "${backup_folder}loceval_diff_$(date +"%Y%m%d%H%M").patch" 
  ```
- # Incremental backups
- As seen in the script above and in the folders, we store **incremental backups**.
	- the nightly state can always be retrieved as `<db>_latest.sql`
	- diffs are created via the [`patch`](https://wiki.archlinux.org/title/Patching_packages) package
	- you can go "back in time", e.g. to restore accidentally deleted information, by using `patch -R <...>`:
	  ```sh
	  patch -R latest_dump.sql -i $(date +"%Y%m%d")_loceval_diff.patch
	  ```
	- see `man patch` for more details