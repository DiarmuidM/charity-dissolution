# Australia Charity Data Download

This is a Python app that allows a user to collect data about Australian charities from the national regulator - <a href="https://www.acnc.gov.au/" target=_blank>Australian Charities and Not-for-profit Commission (ACNC)</a>.

The app is run using the Command Line Interface (CLI); if you are unfamiliar with this approach, then please see the detailed instructions below.

### Step 1 - Install Python

The easiest means of installing Python is to download the free Anaconda distribution of the programming language. Follow the instructions provided:
* <a href="https://www.anaconda.com/distribution/#windows" target=_blank>Windows download</a>
* <a href="https://www.anaconda.com/distribution/#linux" target=_blank>Linux download</a>
* <a href="https://www.anaconda.com/distribution/#macos" target=_blank>Mac download</a>

### Step 2 - Create folder to store code and data

Open your CLI and type the following commands one-by-one:
```
mkdir aus-char-data
cd aus-char-data
```

This creates a new folder on your machine for storing the files. Now place the following files in this folder:
* aus-charity-data-download.py
* requirements.txt

### Step 3 - Create a virtual environment

The next step is to enable the *aus-char-data* folder to run Python code. Open your CLI and type the following command:
```
python -m venv env
```

Now we need to activate the environment, which depends on you are using Windows, Mac or Linux:
```
# Windows
env\Scripts\activate.bat

# Mac/Linux
source env/bin/activate
```
