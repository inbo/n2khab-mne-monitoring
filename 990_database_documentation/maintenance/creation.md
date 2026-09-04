via Python scripts:
- `501_init_loceval.py`
- `601_init_mnmgwdb.py`
In the future, these might be replaced by R scripts.

See [[software/python#virtual environment|python "virtual environments"]].

> [!tip] database modifications
> A good strategy for database adjustments is to run a db init on the `_dev` [[database/mirrors|mirror]] and redirecting the output to a dump file, as follows.

Run these scripts (only set the `_dev` mirror recreation inside it to `True`):
```sh
python 501_init_loceval.py > dump.txt
```

Then, you can then filter the verbose output of the (modified) recreation procedure. These can be *reviewed* and directly applied to `_staging`/`_testing`, then *production*.
This example extracts all permission modifications (*cf.* [[database/userroles|userroles]]).
```sh
 cat dump.txt | grep 'GRANT' | grep -v "test*"
```

Or, if a new column or table were created, find all creation commands which mention them (*cf.* [[maintenance/add column|add column]]).
```sh
cat dump.txt | grep 'is_well_developed_type'
```

If needed, the syntax above might be ported to Windows (with modifications).