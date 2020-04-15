#Scrape Trustee details
#Tom Wallace, Diarmuid McDonnell
#11/10/18
#This file scrapes trustee information from the Charity Commission for Northern Ireland website.

################################# Import packages #################################
from urllib.request import urlopen as uReq
from bs4 import BeautifulSoup as soup
from lxml.html import fromstring
from itertools import cycle
from datetime import datetime
from downloaddate_function import downloaddate
from time import sleep
#from dropbox.files import WriteMode
import requests
import glob
#import dropbox
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
    	if i.xpath('.//td[7][contains(text(),"no")]') or i.xpath('.//td[7][contains(text(),"yes")]'): # None on the list have yes at current time
            #Grabbing IP and corresponding PORT
            proxy = ":".join([i.xpath('.//td[1]/text()')[0], i.xpath('.//td[2]/text()')[0]])
            proxies.add(proxy)
    print('New proxies grabbed.\n')
    return proxies

"""
# Fetch Dropbox authentication
dbtokenpath = 'C:/Users/mcdonndz-local/Desktop/admin/db_token.txt'
#dbtokenpath_pi = '/home/pi/admin/dp_token.txt'
dbtokenfile = open(dbtokenpath, "r")
dbapitoken = dbtokenfile.read()
print(dbapitoken)

dbx = dropbox.Dropbox(dbapitoken) # Create an object for accessing Dropbox API
"""
# Get the current date
ddate = downloaddate()

# Define paths
localdatapath = './'
remotedatapath = './trustee_data/data_raw/' # Dropbox path
remotelogpath = './trustee_data/logs/' # Dropbox path
projpath = './' # Location of syntax

inputfile = remotedatapath + 'ni_charityregister_' + ddate + '.csv'
outputfile = remotedatapath + 'ni_trustee_data_' + ddate + '.csv'
logoutputfile = remotedatapath + 'ni_trustee_log_' + ddate + '.csv'

# Delete output file if already exists
try:
    os.remove(outputfile)
except OSError:
    pass

# Download latest copy of NI charity register from the Commission's data portal
if not os.path.isfile(inputfile):
	import ni_download
	print('Finished executing ni_download.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(10)

print(' ') # Whitespace used to make the output window more readable
print('>>> Run started') # Header of the output, with the start time.
print('\r')

# Create a panda's dataframe from the input CSV #
pd.set_option('precision', 0)

with open(inputfile, 'rb') as f:
	df = pd.read_csv(f)
	print(df.dtypes)

df.reset_index(inplace=True) 
df.set_index(['Reg charity number'], inplace=True) 
regno_list = df.index.values.tolist()
fye_list = df['Date for financial year ending'].values.tolist()
print(len(fye_list)==len(regno_list))
#print(regno_list)

# Define variable names for the output files
varnames = ['Row ID', 'Registered', 'Trustee Name', 'Charity Number', 'Charity Name']
lvarnames = ['timestamp', 'regno', 'url', 'status code', 'execution time']

with open(outputfile, 'a', newline='') as f:
	writer = csv.writer(f, varnames)
	writer.writerow(varnames)

with open(logoutputfile, 'a') as f:
	writer = csv.writer(f, lvarnames)
	writer.writerow(lvarnames)

# Define a counter to track how many rows of the input file the script processes
counter = 1

# Scrape proxies
proxytry = 1
try: #Call the get_proxies function and if it fails go to sleep and try again a up to 7 times
	proxies = get_proxies()
except:
	print('Trying to get proxies:',proxytry)
	sleep(sleeptime)
	proxies = get_proxies()
	proxytry = proxytry + 1
	if proxytry > 6:
		Print('>>> Failed to get proxies. Confirm site is up and relaunch script. <<<')
		quit()
print('Proxies:',proxies) 
proxy_pool = cycle(proxies)

# Loop through list of charity numbers and scrape info from webpages
for ccnum in regno_list: 
 
	starttime = datetime.now() # Track how long it takes to scrape data for each charity

	# Define counter to track number of times the script tries to use a valid proxy
	proxytry = 1
	while proxytry < 1000:
		#try:
		proxy = next(proxy_pool) # Grab a proxy from the pool
		proxytry = 2000
		webadd = 'https://www.charitycommissionni.org.uk/charity-details/?regid=' + str(ccnum) +'&subid=0'
		headers = {'http': proxy, 'https': proxy, 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
		
		# Define counter to track number of webpage request attempts; try three times
		attempt = 1

		try:
			while attempt < 4:

				rorg = requests.get(webadd, headers=headers) # Grab the page using the URL and headers.
				print('\n',proxy) # Checks if script is cycling through proxies
				print(webadd)
				if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
					attempt = 5
					html_org = rorg.text # Get the text elements of the page.
					soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

					################################# Charity and Trustee info #################################

					if not soup_org.find('p', {"class": "pcg-charity-details__amount pcg-charity-details__amount--removed pcg-contrast__color-alt"}): # If the charity isn't removed from the Register then proceed with scraping trustee info
						#try: # This try captures instances where the webpage request was successful but the result is blank page i.e. no charity information
						# Capture charity name
						charityname = soup_org.find('h1', {"class": "pcg-charity-details__title"}).text
						print(charityname)
						charname = charityname

						boardinfo = soup_org.find("div", class_="table-responsive-sm") # Scrape the whole panel
						boardinfo = boardinfo.find_all('tr') # Find all the rows and store them as a list
						del boardinfo[0] # Delete the top line which is the headers
					
						trustee = list(map(lambda x : x.text.strip(), boardinfo)) # The name is in it's own tag so easy to find, map/lambda applies something to every item in a list

						# Data management #

						# Create variables capturing the number of trustees, number of other trusteeships per trustee, and adjust Row ID to begin at 1 

						# Write to JSON and CSV
						dicto = {'ccnum':ccnum, 'charname': charname, 'Trustee':trustee, 'Registered': '1'} # Store the new variables as a dictionary

						#df_json = pd.DataFrame(dicto)
						#df_json.set_index(['ccnum'], inplace=True)
						#df_json.to_json(path_or_buf='Trustee_test_data_loop.json', orient='index')

						df_csv = pd.DataFrame(dicto)
						with open(outputfile, 'a') as f:
							df_csv.to_csv(f, header=False)
						#except:
						#	print('\r')
						#	print('No information available for this charity | regno: ' + str(ccnum))
						#	print('\r')

					elif soup_org.find('div', {"class": "status-description removed"}): # Charity has been removed and therefore trustee information does not exist
						try: # This try captures instances where the webpage request was successful but the result is blank page i.e. no charity information
							remdate = soup_org.find('div', {'class': 'status-description removed'})
							remdate = remdate.text
							print(remreason)

							# Capture charity name
							charityname = soup_org.find('div', {"class": "charity-heading-panel container"}).h1
							print(charityname)
							charname = charityname.text

							# Write to CSV
							dicto_csv={'ccnum':ccnum,  'FYE': '.', 'charname': charname, 'Trustee':'.', 'Other trusteeships':'.', 'Other trusteeships link': '.', 'Registered': '0', 'Reason for removal': remreason} # Store the new variables as a dictionary
							df_csv = pd.DataFrame(dicto_csv, index=[1])
							
							with open(outputfile, 'a') as f:
								df_csv.to_csv(f, header=False)
						except:
							print('\r')
							print('No information available for this charity | regno: ' + str(ccnum))
							print('\r')
					print('\r')
					print('Processed ' + str(counter) + ' rows in the input file')
					counter +=1
				else:
					print('\r')
					print(rorg.status_code, '| Could not resolve address of webpage')
					print('Will try to request webpage a couple more times')
					attempt +=1

				# Export results of script to log file
				runtime = datetime.now() - starttime
				with open(logoutputfile, 'a', newline='') as f:
					writer = csv.writer(f)
					writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), ccnum, webadd, rorg.status_code, runtime])			
			
		except Exception as e:
			print(e) # Could not cycle through the list of proxies
			sleep(1)
			# Scrape proxies again
			proxies = get_proxies()
			print(proxies) 
			proxy_pool = cycle(proxies)
			proxytry +=1

"""
# Upload files to Dropbox
infile = outputfile
outfile = remotedatapath + 'ni_trustee_data_' + ddate + '.csv' # Dataset
loginfile = logoutputfile
logoutfile = remotelogpath + 'ni_trustee_log_' + ddate + '.csv' # Log file

with open(infile, 'rb') as f:
	#print(f.read())
	dbx.files_upload(f.read(), outfile, dropbox.files.WriteMode.overwrite, mute=True)

with open(loginfile, 'rb') as f:
	dbx.files_upload(f.read(), logoutfile, dropbox.files.WriteMode.overwrite, mute=True)	

# Delete contents of localdatapath - NOT CURRENTLY WORKING

try:
	os.remove(infile)
	print('Deleted local file')
except:
	print('Could not delete local file')
"""
print('\r')
print('>>> Finished')