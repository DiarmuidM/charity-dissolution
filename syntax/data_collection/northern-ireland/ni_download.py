## Python script to download a monthly snapshot of the Charity Commission for Northern Ireland's Charity Register, and removed trustees data

# Diarmuid McDonnell
# Created: 26 February 2018
# Last edited: 26 February 2018

import itertools
import json
import csv
import re
import requests
#import dropbox
import os
import os.path
import errno
import urllib
from time import sleep
from downloaddate_function import downloaddate

# Run the downloaddate function to get the date 'benefacts_master.py' was executed.
ddate = downloaddate()

# Fetch Dropbox authentication


# Define paths

rawdatapath = './trustee_data/data_raw/'
projpath = './'

# Define the url where the datasets can be downloaded
regurl = 'http://www.charitycommissionni.org.uk/charity-search/?&exportCSV=1'
#trusteeurl = 'https://www.charitycommissionni.org.uk/media/51003/20171031-register-of-removed-trustees.xls'
csvlink = 'https://www.charitycommissionni.org.uk/umbraco/api/charityApi/ExportSearchResultsToCsv/?pageNumber=1'

# Download Register #

r = requests.get(csvlink, allow_redirects=True)
print(r.status_code, r.headers) # I want to take the date information and use it to name the file and folder

# Write the r.content to a file on Dropbox
outputfile = rawdatapath + '/ni_charityregister_' + ddate + '.csv'
print(outputfile)
outcsv = open(outputfile, 'wb')
outcsv.write(r.content)
outcsv.close()

# Download Removed Trustees #
"""
r = requests.get(trusteeurl, allow_redirects=True)
print(r.status_code, r.headers) # I want to take the date information and use it to name the file and folder

# Write the r.content to a file in the newly created folder
outputfile = rawdatapath + '/ni_removedtrustees_' + ddate + '.csv'
print(outputfile)
outcsv = open(outputfile, 'wb')
outcsv.write(r.content)
outcsv.close()
"""