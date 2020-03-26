# Python script to download US nonprofit data from the Open-Data-for-Nonprofit-Research project on Github:
#		- https://github.com/DiarmuidM/Open-Data-for-Nonprofit-Research

# Diarmuid McDonnell
# Created: 05 March 2018
# Last edited: captured in Github file history

import itertools
import json
import csv
import pandas
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

index1 = 'https://s3.amazonaws.com/irs-form-990/index_2011.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2011
index2 = 'https://s3.amazonaws.com/irs-form-990/index_2012.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2012
index3 = 'https://s3.amazonaws.com/irs-form-990/index_2013.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2013
index4 = 'https://s3.amazonaws.com/irs-form-990/index_2014.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2014
index5 = 'https://s3.amazonaws.com/irs-form-990/index_2015.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2015
index6 = 'https://s3.amazonaws.com/irs-form-990/index_2016.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2016
index7 = 'https://s3.amazonaws.com/irs-form-990/index_2017.json' # IRS INDEX FILE EXEMPT ORGANIZATIONS 2017

# Download data #

files = [index1, index2, index3, index4, index5, index6, index7]
year = 2011

for file in files:

	r = requests.get(file, allow_redirects=True)
	print(r.status_code, r.ok, r.headers)
	# I need to capture the last modified information so I can name the files/decide when to download etc.
	metadata = r.headers
	print(type(metadata))
	lastmod = metadata['Last-Modified']
	print(lastmod)
	print(len(lastmod))

	udate = lastmod[5:16].replace(' ', '')
	print(udate)

	# Write the r.content to a file in the newly created folder
	outputfile_json = datapath + ddate + '/' + 'irs_index_' + str(year) + '_' + udate + '.json'
	print(outputfile_json)
	outjson = open(outputfile_json, 'wb')
	outjson.write(r.content)
	outjson.close()

	# Load the json to a Python object and write to csv

	outputfile_csv = datapath + ddate + '/' + 'irs_index_' + str(year) + '_' + udate + '.csv'

	with open(outputfile_json, 'r') as f:
		data = json.load(f)
		print(len(data.keys()))
	'''
		The json is a dictionary with one item: key=filings2011, value=list of dictionaries.
	'''	

	with open(outputfile_csv, 'w', newline='') as c:
		varnames = data['Filings' + str(year)][0].keys()
		writer = csv.DictWriter(c, varnames)
		print('---------------------')
		print('                     ')
		writer.writeheader()
		writer.writerows(data['Filings' + str(year)])
		
	year +=1

'''
# Append files together to form one dataset #

outputfile = datapath + ddate + '/' + 'irs_index_' + udate + '.json'
file1 = datapath + ddate + '/' + 'irs_index_2011_' + udate + '.json'
file2 = datapath + ddate + '/' + 'irs_index_2012_' + udate + '.json'
file3 = datapath + ddate + '/' + 'irs_index_2013_' + udate + '.json'
file4 = datapath + ddate + '/' + 'irs_index_2014_' + udate + '.json'
file5 = datapath + ddate + '/' + 'irs_index_2015_' + udate + '.json'
file6 = datapath + ddate + '/' + 'irs_index_2016_' + udate + '.json'
file7 = datapath + ddate + '/' + 'irs_index_2017_' + udate + '.json'

afiles = [file1, file2, file3, file4, file5, file6, file7]

'''