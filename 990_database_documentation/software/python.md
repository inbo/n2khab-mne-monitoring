---
aliases:
  - python
tags: 
  - programming
---

### virtual environment
#### initiation
```sh
cd <project_folder>
python -m venv .dbtools
source .dbtools/bin/activate
pip install --upgrade pip -r python_requirements.txt
# pip freeze > python_requirements.txt # to feed back updated requirements
```

#### activation: 
```sh
source .dbtools/bin/activate
```

#### update
*(There are regular incompatibilities with the latest GDAL versions; consider keeping `GDAL==3.12.0.post1`.)*

```sh
nvim python_requirements
:%s/==/>=/g
:wq
pip install --upgrade pip -r python_requirements.txt
# test functionality
pip freeze > python_requirements.txt
# Afterwards, make a git commit.
```