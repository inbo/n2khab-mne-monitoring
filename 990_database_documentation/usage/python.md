cf. [[software/python|python]]
we use virtual environments
Python will be phased out over time in favor of R

## initialization
we use a virtual environment to manage python package versions.
```sh
python -m venv .db_tooldev
source .db_tooldev/bin/activate
pip install --upgrade pip -r python_requirements.txt
```

To update the venv, replace all `==` by `>=` in the `python_requirements.txt` (except for GDAL!) and re-run the pip upgrade command.