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

soi_990_2016 = 'https://www.irs.gov/pub/irs-soi/16eofinextract990.dat' # IRS 990 Financial Returns 2016
soi_990ez_2016 = 'https://www.irs.gov/pub/irs-soi/16eofinextractez.dat' # IRS 990-EZ Financial Returns 2016
soi_990pf_2016 = 'https://www.irs.gov/pub/irs-soi/16eofinextract990pf.dat' # IRS 990-PF Financial Returns 2016

soi_990_2015 = 'https://www.irs.gov/pub/irs-soi/15eofinextract990.dat.dat' # IRS 990 Financial Returns 2015
soi_990ez_2015 = 'https://www.irs.gov/pub/irs-soi/15eofinextractEZ.dat' # IRS 990-EZ Financial Returns 2015
soi_990pf_2015 = 'https://www.irs.gov/pub/irs-soi/15eofinextract990pf.dat' # IRS 990-PF Financial Returns 2015

soi_990_2014 = 'https://www.irs.gov/pub/irs-soi/14eofinextract990.zip' # IRS 990 Financial Returns 2014
soi_990ez_2014 = 'https://www.irs.gov/pub/irs-soi/14eofinextract990ez.zip' # IRS 990-EZ Financial Returns 2014
soi_990pf_2014 = 'https://www.irs.gov/pub/irs-soi/14eofinextract990pf.zip' # IRS 990-PF Financial Returns 2014

soi_990_2013 = 'https://www.irs.gov/pub/irs-soi/13eofinextract990.zip' # IRS 990 Financial Returns 2013
soi_990ez_2013 = 'https://www.irs.gov/pub/irs-soi/13eofinextract990ez.zip' # IRS 990-EZ Financial Returns 2013
soi_990pf_2013 = 'https://www.irs.gov/pub/irs-soi/13eofinextract990pf.zip' # IRS 990-PF Financial Returns 2013

soi_990_2012 = 'https://www.irs.gov/pub/irs-soi/12eofinextract990.zip' # IRS 990 Financial Returns 2012
soi_990ez_2012 = 'https://www.irs.gov/pub/irs-soi/12eofinextract990ez.zip' # IRS 990-EZ Financial Returns 2012
soi_990pf_2012 = 'https://www.irs.gov/pub/irs-soi/12eofinextract990pf.zip' # IRS 990-PF Financial Returns 2012

# Create lists of similar urls
f2016 = [soi_990_2016, soi_990ez_2016, soi_990pf_2016]
f2015 = [soi_990_2015, soi_990ez_2015, soi_990pf_2015]
f2014 = [soi_990_2014, soi_990ez_2014, soi_990pf_2014]
f2013 = [soi_990_2013, soi_990ez_2013, soi_990pf_2013]
f2012 = [soi_990_2012, soi_990ez_2012, soi_990pf_2012]


# Download data #

item = 1

for file in f2016:
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
	outdat = datapath + ddate + '/' + 'irs_soi_990_2016_' + str(item) + '_' + udate + '.dat'
	print(outdat)
	outf = open(outdat, 'wb')
	outf.write(r.content)
	outf.close()

	# Write .dat to .csv
	infile = datapath + ddate + '/' + 'irs_soi_990_2016_' + str(item) + '_' + udate + '.dat'
	outfile = datapath + ddate + '/' + 'irs_soi_990_2016_' + str(item) + '_' + udate + '.csv'

	with open(infile, 'r') as input_file:        
		newLines = []
		for line in input_file:
			newLine = [x.strip() for x in line.split(' ')]
			newLines.append(newLine)

	with open(outfile, 'w', newline='') as output_file:
	    file_writer = csv.writer(output_file)
	    file_writer.writerows(newLines)

	# Increment the file naming counter
	item +=1

#############################################################################################################

item = 1

for file in f2015:
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
	outdat = datapath + ddate + '/' + 'irs_soi_990_2015_' + str(item) + '_' + udate + '.dat'
	print(outdat)
	outf = open(outdat, 'wb')
	outf.write(r.content)
	outf.close()

	# Write .dat to .csv
	infile = datapath + ddate + '/' + 'irs_soi_990_2015_' + str(item) + '_' + udate + '.dat'
	outfile = datapath + ddate + '/' + 'irs_soi_990_2015_' + str(item) + '_' + udate + '.csv'

	with open(infile, 'r') as input_file:        
		newLines = []
		for line in input_file:
			newLine = [x.strip() for x in line.split(' ')]
			newLines.append(newLine)

	with open(outfile, 'w', newline='') as output_file:
	    file_writer = csv.writer(output_file)
	    file_writer.writerows(newLines)

	# Increment the file naming counter
	item +=1
	

#############################################################################################################
'''
for file in f2014:
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

	z = zipfile.ZipFile(io.BytesIO(r.content))
	z.extractall(datapath + ddate)		

#############################################################################################################

for file in f2013:
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

	z = zipfile.ZipFile(io.BytesIO(r.content))
	z.extractall(datapath + ddate)

#############################################################################################################

for file in f2012:
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

	z = zipfile.ZipFile(io.BytesIO(r.content))
	z.extractall(datapath + ddate)
'''