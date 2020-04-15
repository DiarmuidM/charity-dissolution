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

busfile1 = 'https://www.irs.gov/pub/irs-soi/eo1.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 1
busfile2 = 'https://www.irs.gov/pub/irs-soi/eo2.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 2
busfile3 = 'https://www.irs.gov/pub/irs-soi/eo3.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 3
busfile4 = 'https://www.irs.gov/pub/irs-soi/eo4.csv' # IRS MASTER FILE EXEMPT ORGANIZATIONS LIST 4

# Download data #

files = [busfile1, busfile2, busfile3, busfile4]
item = 1

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

	# Write the r.content to a file in the newly created folder #
	outputfile = datapath + ddate + '/' + 'irs_businessfile_' + str(item) + '_' + udate + '.csv'
	print(outputfile)
	outcsv = open(outputfile, 'wb')
	outcsv.write(r.content)
	outcsv.close()
	item +=1

# Append files together to form one dataset #

outputfile = datapath + ddate + '/' + 'irs_businessfiles_' + udate + '.csv'
file1 = datapath + ddate + '/' + 'irs_businessfile_1_' + udate + '.csv'
file2 = datapath + ddate + '/' + 'irs_businessfile_2_' + udate + '.csv'
file3 = datapath + ddate + '/' + 'irs_businessfile_3_' + udate + '.csv'
file4 = datapath + ddate + '/' + 'irs_businessfile_4_' + udate + '.csv'

afiles = [file2, file3, file4]


# Append all of these files together #

fout=open(outputfile, 'a')

# Open the first file and write the contents to the output file:
for line in open(file1):
    fout.write(line)

# Now the remaining files:
for file in afiles:
    f = open(file)
    next(f) # skip the first row
    for line in f:
         fout.write(line)
    f.close() # not really needed
fout.close()