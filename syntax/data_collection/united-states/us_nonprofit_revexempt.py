# Python script to download US nonprofit data from the Open-Data-for-Nonprofit-Research project on Github:
#		- https://github.com/DiarmuidM/Open-Data-for-Nonprofit-Research

# Diarmuid McDonnell
# Created: 05 March 2018
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

revexemp = 'https://apps.irs.gov/pub/epostcard/data-download-revocation.zip' # IRS CURRENT EXEMPT ORGANIZATIONS LIST

# Download data #

r = requests.get(revexemp, allow_redirects=True)
print(r.status_code, r.ok, r.headers)
# I need to capture the last modified information so I can name the files/decide when to download etc.
metadata = r.headers
print(type(metadata))
lastmod = metadata['Last-Modified']
print(lastmod)
print(len(lastmod))
udate = lastmod[5:16].replace(' ', '')
print(udate)

#print(r.content)
z = zipfile.ZipFile(io.BytesIO(r.content))
z.extractall(datapath + ddate)

# Load in .txt file and write to csv #

inputfile = datapath + ddate + '/' + 'data-download-revocation.txt'
outputfile = datapath + ddate + '/' + 'irs_revoked_exemp_orgs_' + udate + '.csv'
# Open the output file
with open(outputfile, 'w', newline='') as outcsv:
	varnames = ["EIN", "Legal_Name", "Doing_Business_As_Name", "Organization_Address", "City", "State", "ZIP_Code", "Country", "Exemption_Type", "Revocation_Date", "Revocation_Posting_Date", "Exemption_Reinstatement_Date"]
	writer = csv.writer(outcsv, varnames)
	writer.writerow(varnames)

	with open(inputfile, 'r') as infile:
		size=sum(1 for _ in infile)		
		print(size)
	with open(inputfile, 'r') as infile:
		reader = csv.reader(infile, delimiter='|')
		for row in reader:
			writer.writerow(row)