# Scrape Trustee details for Australian charities
# Diarmuid McDonnell
# 13/11/18
# This file scrapes trustee information from the ACNC website.
# 
#
# Do not forget to create a requirements.txt file for the Australia scripts
#

################################# Import packages #################################

from bs4 import BeautifulSoup as soup
from datetime import datetime as dt
from time import sleep
import requests
import pandas as pd
import csv
import os


# Get the current date
ddate = dt.now().date()
print(ddate)


# Define paths
localdatapath = '/home/diarmuidmc/environments/mission_accomp/data/aus/'
#localdatapath = 'C:/Users/mcdonndz-local/Desktop/data/temp/'
projpath = './' # Location of syntax

# Define file names and output paths
charids = 'auscharities_web-ids_20190822.csv' # List of website ids for Australian charities
chartweb = 'auscharities_trustees_web_' + str(ddate) + '.csv' # # List of trustees and their website search id
chartdat = 'auscharities_trustees_data_' + str(ddate) + '.csv' # List of trustees and their trusteeships
chartweblog = 'auscharities_trustees_web_log_' + str(ddate) + '.csv' # Log file recording the success of the script
chartdatlog = 'auscharities_trustees_data_log_' + str(ddate) + '.csv' # Log file recording the success of the script

incharids = localdatapath + charids
outchartweb = localdatapath + chartweb
outchartdat = localdatapath + chartdat
outchartweblog = localdatapath + chartweblog
outchartdatlog = localdatapath + chartdatlog


# Delete output files if already exists
files = [outchartweblog, outchartdatlog, outchartweb, outchartdat]
for f in files:
	try:
	    os.remove(f)
	except OSError:
	    pass

# Define variable names for the output files
twebvarnames = ['Trustee Web ID', 'Trustee Name', 'Trustee Role', 'Charity Web ID']
tdatvarnames = ['Trustee Web ID', 'ABN', 'Charity Web ID', 'Charity Name']
lvarnames = ['timestamp', 'Charity Web ID', 'url', 'status code', 'execution time']
ltvarnames = ['timestamp', 'Trustee Web ID', 'url', 'status code', 'execution time']

# Write headers to the output files
with open(outchartweb, 'a', newline='\n') as f:
	writer = csv.writer(f, twebvarnames)
	writer.writerow(twebvarnames)

with open(outchartdat, 'a', newline='\n') as f:
	writer = csv.writer(f, tdatvarnames)
	writer.writerow(tdatvarnames)

with open(outchartweblog, 'a', newline='\n') as f:
	writer = csv.writer(f, lvarnames) # UPDATE #
	writer.writerow(lvarnames)

with open(outchartdatlog, 'a', newline='\n') as f:
	writer = csv.writer(f, ltvarnames) # UPDATE #
	writer.writerow(ltvarnames)

print('\r')
print('>>> Beginning')


#######################################################

######### Charity Trustee Web Details Scrape ##########

#######################################################	

# Read in list of charity API ids
with open(incharids, 'rb') as f:
	df = pd.read_csv(f)
	print(df.dtypes)

# Extract API ids as a list
id_list = df['Charity Web ID'].tolist()
# print(id_list)

# Define a counter to track how many elements of the list the script processes
counter = 1

# Loop through list of charity numbers and scrape trustee ids
for charid in id_list[54725:]: 
 
	starttime = dt.now() # Track how long it takes to scrape data for each charity

	webadd = 'https://www.acnc.gov.au/charity/' + str(charid) # Web address of charity's details
	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
			
	# Define counter to track number of webpage request attempts; try three times
	attempt = 1

	while attempt < 4:

		rorg = requests.get(webadd, headers=headers) # Grab the page using the URL and headers.
		#print(proxy) # Checks if script is cycling through proxies
		
		if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
			print('Status code: ', rorg.status_code)
			attempt = 5 # Successfully requested
			html_org = rorg.text # Get the text elements of the page.
			soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.


			# If there are trustee details on the webpage:

			if soup_org.find('div', {'class': 'field field-name-acnc-node-group-members field-type-ds field-label-hidden'}):
				print('Group charity - no trustee details')
				trustid = 'NULL - Group'
				trustname = 'NULL - Group'
				role = 'NULL - Group'

				with open(outchartweb, 'a', newline='\n') as f:
					writer = csv.writer(f)
					row = trustid, trustname, role, charid
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


			elif soup_org.find('div', {'class': 'col-xs-12 col-sm-6 col-md-4 col-lg-3 person'}):
				print('Found trustee details')
				trusteedetails = soup_org.find_all('div', {'class': 'col-xs-12 col-sm-6 col-md-4 col-lg-3 person'})
				print(trusteedetails)
				print(type(trusteedetails))

				for el in trusteedetails:
					# Find link to trustee profile i.e. the API ID
					trustlink = el.find('a').get('href')
					#print(charlink) # now extract the unnecessary text (i.e. '/charity/')
					trustid = trustlink[16:]
					#print(trustid)

					# Find trustee name and role
					trustname = el.find('h4').text
					#print(trustname)
					role = el.find('p').text
					#print(role)

					with open(outchartweb, 'a', newline='\n') as f:
						writer = csv.writer(f)
						row = trustid, trustname, role, charid
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

			else: # no trustee details on webpage (e.g. revoked charity)
				print('Could not find trustee details e.g. charity status is revoked')
				trustid = 'NULL'
				trustname = 'NULL'
				role = 'NULL'

				with open(outchartweb, 'a', newline='\n') as f:
					writer = csv.writer(f)
					row = trustid, trustname, role, charid
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
		runtime = dt.now() - starttime
		with open(outchartweblog, 'a', newline='') as f:
			writer = csv.writer(f)
			writer.writerow([dt.today().strftime('%Y%m%d %H:%M'), charid, webadd, rorg.status_code, runtime])			
				
print('\r')
print('>>> Finished searching for trustee web ids')
sleep(10)


#######################################################

############ Charity Trusteeship Scrape ###############

#######################################################	


print('\r')
print('>>> Beginning search for trusteeships')


# Read in list of trustee ids
with open(outchartweb, 'r') as f:
	df = pd.read_csv(f)
	print(df.dtypes)

# Extract ids as a list
id_list = df['Trustee Web ID'].tolist()
print(id_list)
id_list_clean = [x for x in id_list if str(x) != 'nan']
print(id_list_clean)

# Define a counter to track how many elements of the list the script processes
counter = 1

# Loop through list of charity numbers and scrape info from webpages
for tid in id_list_clean: 
 
	starttime = dt.now() # Track how long it takes to scrape data for each charity

	webadd = 'https://www.acnc.gov.au/charity/people/' + str(tid) # Web address of charity's details
	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
	
	# Define counter to track number of webpage request attempts; try three times
	attempt = 1

	while attempt < 4:

		rorg = requests.get(webadd, headers=headers) # Grab the page using the URL and headers.
		#print(proxy) # Checks if script is cycling through proxies
		
		if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
			attempt = 5 # Successfully requested webpage
			html_org = rorg.text # Get the text elements of the page.
			soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

			trusteeshipdetails = soup_org.find('tbody').find_all('tr')
			#print(trusteeshipdetails)

			for row in trusteeshipdetails:
				td_list = row.find_all('td')
				# Get relevant tds and write to output file
				abn = td_list[0].text.strip() # ABN
				charid = td_list[1].find('a').get('href') # Charity web id
				charid = charid[9:]
				print(charid)
				charname = td_list[1].text.strip() # Charity name
				row = tid, abn, charid, charname
				#print(row)	
				
				with open(outchartdat, 'a', newline='') as f:
					writer = csv.writer(f)
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
		runtime = dt.now() - starttime
		with open(outchartdatlog, 'a', newline='') as f:
			writer = csv.writer(f)
			writer.writerow([dt.today().strftime('%Y%m%d %H:%M'), tid, webadd, rorg.status_code, runtime])			
				
print('\r')
print('>>> Finished searching for trustee web ids')


print('\r')
print('End of script')