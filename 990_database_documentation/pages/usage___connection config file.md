- `.conf`/`.ini` file to store login credentials
- to be accessed from within [[usage/R]] or [[usage/python]]
- ## example `inbopostgis_server.conf`
	- ```ini
	  [dumpall]
	  host = <host>
	  port = <port>
	  user = <readonly_user>
	  
	  #### LOCEVAL ####
	  
	  ### (4) production
	  # This is the live environment with real data.
	  # It is the least volatile, best backed-up of our database mirrors.
	  [loceval]
	  folder = loceval_db_structure
	  host = <host>
	  port = <port>
	  database = loceval
	  user = <db_admin>
	  
	  ### (3) testing
	  # The testing mirror is an exact copy of the production database, and
	  # regularly re-copied over. Changes to the data on "testing" are non-permanent.
	  [loceval-testing]
	  folder = loceval_dev_structure
	  host = <host>
	  port = <port>
	  database = loceval_testing
	  user = <db_superuser>
	  password = ***********
	  
	  # [...]
	  ```