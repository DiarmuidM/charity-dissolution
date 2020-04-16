# Australia Charity Data Download

This is a Python script that allows a user to collect data about Australian charities from the national regulator - <a href="https://www.acnc.gov.au/" target=_blank>Australian Charities and Not-for-profit Commission (ACNC)</a>.

The script is run using the Command Line Interface (CLI); Don't worry if you are unfamiliar with this approach, detailed instructions are provided below.

### Step 1 - Install Python

The easiest means of installing Python is to download the free Anaconda distribution of the programming language. Follow the instructions provided:
* <a href="https://www.anaconda.com/distribution/#windows" target=_blank>Windows download</a>
* <a href="https://www.anaconda.com/distribution/#linux" target=_blank>Linux download</a>
* <a href="https://www.anaconda.com/distribution/#macos" target=_blank>Mac download</a>

### Step 2 - Create folder to store code and data

Open your CLI and type the following commands one-by-one (ignore ones beginning with #):
```
# Windows
mkdir aus-char-data
cd aus-char-data
```

This creates a new folder on your machine for storing the files. Now place the following files in this folder:
* aus-charity-data-download.py
* requirements.txt

### Step 3 - Create a virtual environment

The next step is to enable the *aus-char-data* folder to run Python code:
```
python -m venv env
```

Now we need to activate the environment:
```
# Windows
env\Scripts\activate.bat

# Mac/Linux
source env/bin/activate
```

### Step 4 - Run a test

Let's check we can execute the code:
```
python aus-charity-data-download.py test
```

You should see some text putput if the code runs successfully.

### Step 5 - Run other functions

Now that you can run the code, it's time to download the data. First, see which functions are available:
```
python aus-charity-data-download.py -h
```

If this is your first time running this script, we suggest you download the Register of Charities first as other functions are dependent on this dataset:
```
python aus-charity-data-download.py roc
```
