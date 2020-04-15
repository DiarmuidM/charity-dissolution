# Australia Charity Data Download

This is a Python script that allows a user to collect data about Australian charities from the national regulator - <a href="https://www.acnc.gov.au/" target=_blank>Australian Charities and Not-for-profit Commission (ACNC)</a>.

The script is run using the Command Line Interface (CLI); Don't worry if you are unfamiliar with this approach, detailed instructions are provided below.

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

### Step 4 - Run test

Let's check we can execute the code. Type the following into the CLI:
```
python aus-charity-data-download.py test
```

### Step 5 - Run other functions

Now that you can run the code, it's time to download the data. Type the following into the CLI to see which functions you can run:
```
python aus-charity-data-download.py -h
```

If this is your first time running this script, we suggest you download the Register of Charities first as other functions are dependent on this dataset:
```
python aus-charity-data-download.py roc
```
