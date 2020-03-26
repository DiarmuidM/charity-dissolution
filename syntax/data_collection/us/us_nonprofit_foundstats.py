# Python script to download US nonprofit data from the Foundation Stats API:
#		- http://data.foundationcenter.org/about.html#api

# Diarmuid McDonnell
# Created: 09 March 2018
# Last edited: captured in Github file history

import itertools
import json
import csv
import re
import requests, zipfile, io
import os
import os.path
import errno
import urllib
from time import sleep
from bs4 import BeautifulSoup
from downloaddate_function import downloaddate


# Define the path where my API key is
tokenpath = "C:/Users/mcdonndz-local/Desktop/admin/fsapitoken.txt" # "C:/Users/mcdonndz-local/Desktop/admin/chapitoken.txt"


# Open fsapitoken.txt in read mode, print to the screen and create an object that stores the API access request
tokenfile = open(tokenpath, "r")
fsapitoken = tokenfile.read()
print(fsapitoken)


# Run the downloaddate function to get the date 'benefacts_master.py' was executed.
ddate = downloaddate()

# Define project and data paths #
projpath = 'C:/Users/mcdonndz-local/Desktop/github/us_nonprofit_data/'
datapath = 'C:/Users/mcdonndz-local/Desktop/data/us_nonprofit_data/data_raw/'

print(projpath)
print(datapath)


# Create a folder for the download to be saved in #
try:
	os.mkdir(datapath+ddate)
except:
	print('Folder already exists')


# Define urls where data can be downloaded #

url = "https://api.foundationcenter.org/v2.0/aggregates/funding"
opts = {"year": 2015, "subject": "SA"}

req = request.Request(url, data=json.dumps(opts).encode('utf8'),
                      headers={"Content-Type": "application/json"})
req.add_header("x-fc-api-key", fsapitoken)

response = request.urlopen(req).read().decode('utf8')
response_dict = json.loads(response)
print(response_dict["data"]["results"][0]["number_of_grants"])