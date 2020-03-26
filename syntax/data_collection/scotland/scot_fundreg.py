## Python script to download a weekly snapshot of the Scottish Fundraising Charity Register

# Diarmuid McDonnell
# Created: 25 October 2018
# Last edited: captured in Github file history

import itertools
import json
import csv
import re
import requests
import os
import os.path
import errno
import urllib
from time import sleep
from bs4 import BeautifulSoup as soup
from datetime import datetime
from downloaddate_function import downloaddate

# Run the downloaddate function to get the date 'benefacts_master.py' was executed.
ddate = downloaddate()

projpath = 'C:/Users/mcdonndz-local/Desktop/github/scotland_charity_data/'
datapath = 'C:/Users/mcdonndz-local/Desktop/data/scotland_charity_data/data_raw/'

print(projpath)
print(datapath)

# Create a folder for the download to be saved in #
try:
	os.mkdir(datapath+ddate)
except:
	print('Folder already exists')

print(' ') # Whitespace used to make the output window more readable
print('>>> Run started') # Header of the output, with the start time.
print('\r')

fundurl = 'https://www.goodfundraising.scot/fundraising-guarantee/fundraising-guarantee-register-of-charities'
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.

#starttime = datetime.now() # Track how long it takes to scrape data

reg = requests.get(fundurl, headers=headers) # Request webpage
if reg.status_code==200: # If successfully requested then proceed
	print(reg.status_code)
	html_org = reg.text # Get the text elements of the page.
	soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

	pagedetails = soup_org.find_all('p')
	#print(pagedetails) # The second element of the list contains charity details
	chardetails = pagedetails[1]
	#print(chardetails)
	data = [x for x in chardetails if not hasattr(x, "name") or not x.name == "br"]
	print(len(data))
	for el in data:
		print(el)
	#print(data)
	regchar = str(len(data))
	print(regchar)
else:
	print('Could not request webpage')	