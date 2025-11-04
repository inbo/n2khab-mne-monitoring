alias:: python
tags:: programming

- #### virtual environment
	- initiation:
	  ```sh
	  cd <project_folder>
	  python -m venv .dbinit
	  source .dbinit/bin/activate
	  pip install --upgrade pip
	  pip install --upgrade -r python_requirements.txt
	  # pip freeze > python_requirements.txt # to feed back updated requirements
	  ```
	- activation:
	  ```sh
	  source .dbinit/bin/activate
	  ```