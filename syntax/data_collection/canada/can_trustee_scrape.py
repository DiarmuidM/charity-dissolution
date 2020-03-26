# Scrape information returns details
# Diarmuid McDonnell
# 27/11/18
# This file scrapes lists of information returns for charities from the CRA website.

#https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/t3010/v23/t3010DrctrsTrstsLkOffcls_dsplyovrvw

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
charinf = 'cancharities_infreturns_data_20181128.csv' # List of information returns
chartdat = 'cancharities_trustees_data_' + ddate + '.csv' # List of trustees
chartdatlog = 'cancharities_trustees_data_log_' + ddate + '.csv' # Log file recording the success of the script

incharinf = localdatapath + charinf
outchartdat = localdatapath + chartdat
outchartdatlog = localdatapath + chartdatlog


# Delete output files if already exists
files = [outchartdatlog, outchartdat]
for f in files:
	try:
	    os.remove(f)
	except OSError:
	    pass

# Download latest copy of Canada charity register from the CRA's website
if not os.path.isfile(incharinf):
	import can_infreturn_scrape
	print('Finished executing can_infreturn_scrape.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(10)
else:
	print('Already downloaded links to information returns')

print(' ') # Whitespace used to make the output window more readable
print('>>> Run started') # Header of the output, with the start time.
print('\r')

# Define variable names for the output files
tdatvarnames = ['Charity ID', 'FYE', 'Trustee Name', 'Role', 'Start Date', 'End Date', 'Arms Length', 'Note']
lvarnames = ['timestamp', 'Charity ID', 'FYE', 'url', 'status code', 'execution time']

# Write headers to the output files
with open(outchartdat, 'a', newline='\n') as f:
	writer = csv.writer(f, tdatvarnames)
	writer.writerow(tdatvarnames)

with open(outchartdatlog, 'a', newline='\n') as f:
	writer = csv.writer(f, lvarnames) # UPDATE #
	writer.writerow(lvarnames)


#######################################################

############## Charity Trustee Scrape #################

#######################################################	

# Read in list of charity API ids
with open(incharinf, 'rb') as f:
	df = pd.read_csv(f, encoding='latin1', index_col=False, usecols=[0,1])
	print(df.dtypes)
	#print(df)

# Convert column values to lists
id_list = df['Charity ID'].tolist()
fye_list = df['FYE'].tolist()
print(len(id_list))
print(len(fye_list)) # Lists are the same length and ordered by charity id

# Define a counter to track how many elements of the list the script processes
counter = 1

# Scrape proxies
proxies = get_proxies()
print(proxies) 
proxy_pool = cycle(proxies)
'''
	#Need a try except here where the script doesn't progress if set().
'''

# Loop through lists of charity numbers and fyes and scrape info from webpages
for charid, fye in zip(id_list, fye_list):
 
	starttime = datetime.now() # Track how long it takes to scrape data for each charity

	# Define counter to track number of times the script tries to use a valid proxy
	proxytry = 1
	while proxytry < 1000:
		try:
			proxy = next(proxy_pool) # Grab a proxy from the pool
			proxytry = 2000
			webadd = 'https://apps.cra-arc.gc.ca/ebci/haip/srch/t3010form23officers-eng.action?b=' + str(charid) + '&fpe=' + str(fye) # Web address of charity's  list of returns
			headers = {'http': proxy, 'https': proxy, 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
			
			# Define counter to track number of webpage request attempts; try three times
			attempt = 1

			while attempt < 4:

				print(webadd)
				rorg = requests.get(webadd, headers=headers) # Grab the page using the URL and headers.
				#print(proxy) # Checks if script is cycling through proxies
				
				if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
					attempt = 5
					html_org = rorg.text # Get the text elements of the page.
					soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

					if soup_org.find_all('div', {'class': 'brdr-tp brdr-bttm'}):
						trusteedetails = soup_org.find_all('div', {'class': 'brdr-tp brdr-bttm'})
						#print(trusteedetails)

						for el in trusteedetails:
							trustinf = el.find_all('li')
							print(len(trustinf))
							tname = trustinf[0].text.replace('Full name: ', '')
							role = trustinf[4].text.replace('Position: ', '')
							sdate = trustinf[2].text.replace('Start Date: ', '')
							edate = trustinf[3].text.replace('End Date: ', '')
							armsl = trustinf[5].text.replace("At arm's length with other Directors, etc.?: ", '')
							note = '.'

							with open(outchartdat, 'a', newline='\n') as f:
								writer = csv.writer(f)
								row = charid, fye, tname, role, sdate, edate, armsl, note
								print(row)
								writer.writerow(row)
					else:
						print("This charity's trustee information return is not available online.")
						tname = '.'
						role = '.'
						sdate = '.'
						edate = '.'
						armsl = '.'
						note = "This charity's trustee information return is not available online."

						with open(outchartdat, 'a', newline='\n') as f:
							writer = csv.writer(f)
							row = charid, fye, tname, role, sdate, edate, armsl, note
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
				with open(outchartdatlog, 'a', newline='') as f:
					writer = csv.writer(f)
					writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), charid, fye, webadd, rorg.status_code, runtime])			
				
		except Exception as e:
			print(e) # Could not cycle through the list of proxies
			sleep(1)
			# Scrape proxies again
			proxies = get_proxies()
			print(proxies) 
			proxy_pool = cycle(proxies)
			proxytry +=1

print('\r')
print('>>> Finished searching for trustees')

'''
# Upload files to Dropbox
dtweb = remotedatapath + chartweb
dtdat = remotedatapath + chartdat
dtweblog = remotelogpath + chartweblog
dtdatlog = remotelogpath + chartdatlog

with open(outchartweb, 'rb') as f:
	#print(f.read())
	dbx.files_upload(f.read(), dtweb, mute=True, mode=dropbox.files.WriteMode.overwrite)
	print('Uploaded ', outchartweb, ' to Dropbox')

with open(outchartdat, 'rb') as f:
	#print(f.read())
	dbx.files_upload(f.read(), dtdat, mute=True, mode=dropbox.files.WriteMode.overwrite)
	print('Uploaded ', outchartdat, ' to Dropbox')

with open(outchartweblog, 'rb') as f:
	dbx.files_upload(f.read(), dtweblog, mute=True, mode=dropbox.files.WriteMode.overwrite)	
	print('Uploaded ', outchartweblog, ' to Dropbox')

with open(outchartdatlog, 'rb') as f:
	dbx.files_upload(f.read(), dtdatlog, mute=True, mode=dropbox.files.WriteMode.overwrite)	
	print('Uploaded ', outchartdatlog, ' to Dropbox')

print('\r')
print('End of script')
'''