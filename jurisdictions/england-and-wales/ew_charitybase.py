## Python script to download monthly update of data from charitybase API

# Diarmuid McDonnell
# Created: 16 May 2018
# Last edited: captured in Github file history

#######Set path#######
projpath = './' # Set the base path and all other paths branch off it

#######Import packages#######
import json
import csv
import re
import requests, zipfile, io
import os
import os.path
import errno
import urllib
import sys
from time import sleep
from bs4 import BeautifulSoup
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import downloaddate

#######Main program#######
# Run the downloaddate function to get today's date
ddate = downloaddate()

datapath = projpath + 'ew_download/Charity_base'
if not os.path.exists(datapath):
    os.makedirs(datapath)

print(projpath)
print(datapath)

# Define API endpoint

main_url = 'https://charitybase.uk/api/v0.2.0/charities' # returns Data download webpage

# Request data from API

r = requests.get(main_url, allow_redirects=True)
print(r.status_code, r.headers) # I want to take this information and use it to name the files and folders
metadata = r.headers
print(metadata)
print(type(metadata))
print(metadata['Content-Type']) # json format

print(type(r.content))
bdata = r.content.decode('utf-8')
print(bdata)
print(type(bdata))
data = json.loads(bdata) # fails at this point - bdata isn't json it's string and not sure what info is needed from it/if it is there at all. Json download on https://charitybase.uk/ isn't fucntioning so could be due to that
print(data) # Returns a dictionary with some metadata fields and one data field ['charities'] which is a list of dictionaries.
print(len(data))
"""
cbdata = datapath + 'ew_charitybase_' + ddate + '.json'

# Export the data to a .json file
with open(cbdata, 'w') as cbdatajson:
	json.dump(data, cbdatajson)

# Read json data and store in object 'f'
with open(cbdata, 'r') as f:
	data = json.load(f)
print(data)	

# Open a csv and write to it
cbdatacsv = datapath + 'ew_charitybase_' + ddate + '.csv'

with open(cbdatacsv, 'w', newline='') as outcsv:
	varnames = data['charities'][0].keys()
	dict_writer = csv.DictWriter(outcsv, varnames)
	dict_writer.writeheader()
	dict_writer.writerows(data['charities'])


print('                       ')
print('Finished downloading data from charitybase API')

## Write metadata fields in dictionary to a json file also ##

############################################################################################################

# End of data download #

############################################################################################################
"""