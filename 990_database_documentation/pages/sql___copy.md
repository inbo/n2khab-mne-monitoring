- dump table to `.csv` file
- ```sql
  \COPY (
      <query>
  ) TO '/tmp/path/to/file.csv' With CSV DELIMITER ',' HEADER;
  ```