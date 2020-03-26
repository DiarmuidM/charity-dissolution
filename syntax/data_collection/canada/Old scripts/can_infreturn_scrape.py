# Scrape information returns details
# Diarmuid McDonnell
# 27/11/18
# This file scrapes lists of information returns for charities from the CRA website.

#Scrape list of links for each report (quickview and fullview) - try and get ones that aren't on the page, see if they exist, write all atempts to file. Just scrape the links

################################# Import packages #################################
from bs4 import BeautifulSoup as soup
from lxml.html import fromstring
from itertools import cycle
from datetime import datetime
from downloaddate_function import downloaddate
from time import sleep
import requests
import dropbox
import pandas as pd
import numpy as np
import csv
import os

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

# Define file names and output paths
charreg = 'canada_register_20181127.csv' # Charity Register
charinf = 'cancharities_infreturns_data_' + ddate + '.csv' # List of trustees
charinflog = 'cancharities_infreturns_data_log_' + ddate + '.csv' # Log file recording the success of the script

incharreg = localdatapath + charreg
outcharinf = localdatapath + charinf
outcharinflog = localdatapath + charinflog


# Delete output files if already exists
files = [outcharinflog, outcharinf]
for f in files:
	try:
	    os.remove(f)
	except OSError:
	    pass

# Download latest copy of Canada charity register from the CRA's website
if not os.path.isfile(incharreg):
	import canada_charity_download
	print('Finished executing canada_charity_download.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(10)
else:
	print('Already downloaded charity register extract')


print(' ') # Whitespace used to make the output window more readable
print('>>> Run started') # Header of the output, with the start time.
print('\r')

# Define variable names for the output files
varnames = ['Charity ID', 'FYE', 'Full View', 'Quick View', 'Note']
lvarnames = ['timestamp', 'Charity ID', 'url', 'status code', 'execution time']

# Write headers to the output files
with open(outcharinf, 'a', newline='\n') as f:
	writer = csv.writer(f, varnames)
	writer.writerow(varnames)

with open(outcharinflog, 'a', newline='\n') as f:
	writer = csv.writer(f, lvarnames) # UPDATE #
	writer.writerow(lvarnames)


#######################################################

######### Charity Information Returns Scrape ##########

#######################################################	

# Read in list of charity API ids
with open(incharreg, 'rb') as f:
	df = pd.read_csv(f, encoding='latin1', usecols=[0], index_col=False)
	print(df.dtypes)
	print(df.columns)
	#print(df['BN/Registration Number'])


# Extract API ids as a list
id_list = df['BN/Registration Number'].tolist()
#print(id_list)

# Define a counter to track how many elements of the list the script processes
counter = 1

# Scrape proxies
proxies = get_proxies()
print(proxies) 
proxy_pool = cycle(proxies)
'''
#	Need a try except here where the script doesn't progress if set().
'''

# Loop through list of charity numbers and scrape info from webpages
for charid in id_list[0:10]: 
 
	starttime = datetime.now() # Track how long it takes to scrape data for each charity

	# Define counter to track number of times the script tries to use a valid proxy
	proxytry = 1
	while proxytry < 1000:
		try:
			proxy = next(proxy_pool) # Grab a proxy from the pool
			proxytry = 2000
			webadd = 'https://apps.cra-arc.gc.ca/ebci/haip/srch/t3010returnlist-eng.action?b=' + str(charid) # Web address of charity's  list of returns
			headers = {'http': proxy, 'https': proxy, 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
			
			# Define counter to track number of webpage request attempts; try three times
			attempt = 1

			while attempt < 4:

				rorg = requests.get(webadd, headers=headers) # Grab the page using the URL and headers.
				#print(proxy) # Checks if script is cycling through proxies
				
				if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
					attempt = 5
					html_org = rorg.text # Get the text elements of the page.
					soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

					if soup_org.find_all('div', {'class': ' '}): # If this class exists then collect information return data
						returndetails = soup_org.find_all('div', {'class': ' '})
						print(len(returndetails))

						for el in returndetails:
							if el.find('div', {'class': 'col-sm-3 col-md-3 col-lg-3 mrgn-tp-md text-center'}): # if this class is found, proceed as follows (full view and quick view)
								fye = el.find('div', {'class': 'col-sm-3 col-md-3 col-lg-3 mrgn-tp-md text-center'}).text
							elif el.find('div', {'class': ' col-sm-3 col-md-3 col-lg-3 mrgn-tp-md text-center'}): # else if this class is founc, proceed as follows (no quick view)
								fye = el.find('div', {'class': ' col-sm-3 col-md-3 col-lg-3 mrgn-tp-md text-center'}).text
							
							links = el.find_all('a', {'class': 'list-group-item text-center'})
							if len(links)==2:
								fview = links[0].get('href')
								qview = links[1].get('href')
							elif len(links)==1:
								fview = links[0].get('href')
								qview = 'N/A'
							note = '.'			

							with open(outcharinf, 'a', newline='\n') as f:
								writer = csv.writer(f)
								row = charid, fye, fview, qview, note
								print(row)
								writer.writerow(row)

					else:
						print("This charity's annual information return is not available online.")
						fye = '.'
						fview = '.'
						qview = '.'
						note = "This charity's annual information return is not available online."

						with open(outcharinf, 'a', newline='\n') as f:
							writer = csv.writer(f)
							row = charid, fye, fview, qview, note
							print(row)
							writer.writerow(row)

					print('__________________________________________________________________________')
					print('                                                                          ')
					print('                                                                          ')
					print(counter)
					print('                                                                          ')
					print('                                                                          ')
					print('__________________________________________________________________________')
					counter +=1	

				else:
					print('\r')
					print(rorg.status_code, '| Could not resolve address of webpage')
					print('Will try to request webpage a couple more times')
					attempt +=1
				
				# Export results of script to log file
				runtime = datetime.now() - starttime
				with open(outcharinflog, 'a', newline='') as f:
					writer = csv.writer(f)
					writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), charid, webadd, rorg.status_code, runtime])			
				
		except Exception as e:
			print(e) # Could not cycle through the list of proxies
			sleep(1)
			# Scrape proxies again
			proxies = get_proxies()
			print(proxies) 
			proxy_pool = cycle(proxies)
			proxytry +=1

print('\r')
print('>>> Finished searching for information returns')