#Scrape Trustee details
#Diarmuid McDonnell
#18/10/18
#This file scrapes trustee information from the Charities Regulator website.

################################# Import packages #################################
from urllib.request import urlopen as uReq
from bs4 import BeautifulSoup as soup
from lxml.html import fromstring
from itertools import cycle
from datetime import datetime
from downloaddate_function import downloaddate
from time import sleep
from dropbox.files import WriteMode
from selenium import webdriver
import requests
import json
import dropbox
import pandas as pd
import csv
import os
import io
import numpy as np

# Define a function for generating proxies
def get_proxies():
    url = 'https://free-proxy-list.net/'
    response = requests.get(url)
    parser = fromstring(response.text)
    proxies = set()
    for i in parser.xpath('//tbody/tr')[:10]:
        if i.xpath('.//td[7][contains(text(),"yes")]'):
            #Grabbing IP and corresponding PORT
            proxy = ":".join([i.xpath('.//td[1]/text()')[0], i.xpath('.//td[2]/text()')[0]])
            proxies.add(proxy)
    return proxies

# Fetch Dropbox authentication
dbtokenpath = 'C:/Users/mcdonndz-local/Desktop/admin/db_token.txt'
#dbtokenpath_pi = '/home/pi/admin/dp_token.txt'
dbtokenfile = open(dbtokenpath, "r")
dbapitoken = dbtokenfile.read()
print(dbapitoken)

dbx = dropbox.Dropbox(dbapitoken) # Create an object for accessing Dropbox API

# Get the current date
ddate = downloaddate()

# Define paths
localdatapath = 'C:/Users/mcdonndz-local/Desktop/data/temp/'
remotedatapath = '/trustee_data/data_raw/' # Dropbox path
remotelogpath = '/trustee_data/logs/' # Dropbox path
projpath = './' # Location of syntax

inputfile = localdatapath + 'ire_charityregister_' + ddate + '.xlsx'
outputfile = localdatapath + 'ire_trustee_data_' + ddate + '.json'
logoutputfile = localdatapath + 'ire_trustee_log_' + ddate + '.csv'

# Delete output file if already exists
try:
    os.remove(outputfile)
except OSError:
    pass

# Download latest copy of IRE charity register from the Regulator's website
if not os.path.isfile(inputfile):
	import ire_download
	print('Finished executing ire_download.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(10)
else:
	print('Already downloaded charity register extract')

# Create a panda's dataframe from the CSV
with open(inputfile, 'rb') as f:
	df = pd.read_excel(f, sheet_name='Public Register')
	print(df.dtypes)

df.reset_index(inplace=True) 
df.set_index(['Registered Charity Number'], inplace=True) 
regid_list = df.index.values.tolist()
#print(regid_list)

# Define variable names for the output files
logvarnames = ['timestamp', 'regid', 'entid', 'success', 'attempts', 'status code', 'execution time']

with open(logoutputfile, 'a') as f:
    writer = csv.writer(f, logvarnames)
    writer.writerow(logvarnames)

# Define a counter to track how many rows of the input file the script processes
counter = 1

# Scrape proxies
proxies = get_proxies()
print(proxies) 
proxy_pool = cycle(proxies)

print(' ') # Whitespace used to make the output window more readable
print('>>> Run started') # Header of the output, with the start time.
print('\r')

trustee_list = [] # Create a list for storing the results of the scrape

# Loop through list of charity numbers and scrape info from webpages
for regid in regid_list[0:10]: 
 
	starttime = datetime.now() # Track how long it takes to scrape data for each charity

	# Define counter to track number of times the script tries to use a valid proxy
	proxytry = 1
	while proxytry < 1000:
		try:
			proxy = next(proxy_pool) # Grab a proxy from the pool
			proxytry = 2000
			charurl = 'https://www.charitiesregulator.ie/umbraco/api/search/getcharitybyregid?regid=' + str(regid)
			headers = {'http': proxy, 'https': proxy, 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
			
			# Define counter to track number of webpage request attempts; try three times
			attempt = 1

			while attempt < 4:

				rorg = requests.get(charurl, headers=headers) # Grab the page using the URL and headers.
				#print(proxy) # Checks if script is cycling through proxies
				
				if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
					chardata = rorg.json()
					entid = chardata['data'][0]['entityId']

					# Request page using entid
					trusturl = 'https://www.charitiesregulator.ie/umbraco/api/search/getentitydetailsbyid?id=' + str(entid)
					rtrust = requests.get(trusturl, headers=headers) # Grab the page using the URL and headers.

					charinfo = rtrust.json()
					trustees = charinfo['data']['trusteeDetails'] 
					print(trustees)

					#fye = charinfo['data']['annualReturnBarcodes'] # Get financial year end date the trustee information pertains to
					#fye = fye[0:10]
					#print(fye)
					'''
						Might have to get this information from the Annual Returns sheet in the Charity Register.
					'''
					if len(trustees) == 0:
						chardetails = {'name': '.', "position": ".", "startDate": ".",'regid': str(regid), 'entityid': str(entid)}
						trustees.append(chardetails)
					else:
						for el in trustees: # Add charity details to the list of trustee data
							el['regid'] = str(regid)
							el['entityid'] = str(entid)
					
					trustee_list.append(trustees) # Append trustee data to trustee_list

					success = 1
					runtime = datetime.now() - starttime
					attempt = 5
				else:
					print('\r')
					print(rorg.status_code, '| Could not resolve address of webpage')
					print('Will try to request webpage a couple more times')
					attempt +=1
					success = 0

				# Write the results of the scrape search to the log file
				runtime = datetime.now() - starttime
				with open(logoutputfile, 'a', newline='') as f:
					writer = csv.writer(f)
					writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), str(regid), str(entid), success, attempt, rorg.status_code, runtime])

		except Exception as e:
			print(e) # Could not cycle through the list of proxies
			sleep(1)
			# Scrape proxies again
			proxies = get_proxies()
			print(proxies) 
			proxy_pool = cycle(proxies)
			proxytry +=1

# Export the results to a json file
with open(outputfile, 'w') as f: 
    json.dump(trustee_list, f)

# Upload files to Dropbox
infile = outputfile
outfile = remotedatapath + 'ire_trustee_data_' + ddate + '.json' # Dataset
loginfile = logoutputfile
logoutfile = remotelogpath + 'ire_trustee_log_' + ddate + '.csv' # Log file

with open(infile, 'rb') as f:
	#print(f.read())
	dbx.files_upload(f.read(), outfile, dropbox.files.WriteMode.overwrite, mute=True)

with open(loginfile, 'rb') as f:
	dbx.files_upload(f.read(), logoutfile, dropbox.files.WriteMode.overwrite, mute=True)	

print('\r')
print('>>> Finished')