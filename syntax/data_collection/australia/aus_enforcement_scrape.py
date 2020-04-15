# Scrape charity enforcement and revocation details
# Diarmuid McDonnell
# 13/11/18
# This file scrapes enforcement and revocation information from the ACNC website.

################################# Import packages #################################

from bs4 import BeautifulSoup as soup
from datetime import datetime as dt
from time import sleep
import requests
import random
import pandas as pd
import csv
import os


# Get the current date
ddate = dt.now().date()
print(ddate)

# Define paths
localdatapath = '/home/diarmuidmc/environments/mission_accomp/data/aus/'
#localdatapath = 'C:/Users/mcdonndz-local/Dropbox/mission_accomp/data_raw/aus/'
projpath = './' # Location of syntax

# Define file names and output paths
charweb = 'auscharities_web-ids_2019-09-19.csv' # List of charities and their website search id
charenf = 'auscharities_enf_' + str(ddate) + '.csv' # File recording enforcement action history of charities
charrev = 'auscharities_rev_' + str(ddate) + '.csv' # File recording registration and revocation history of charities
charlog = 'auscharities_enf_rev_log_' + str(ddate) + '.csv' # Log file recording the success of the script

incharweb = localdatapath + charweb
outcharenf = localdatapath + charenf
outcharrev = localdatapath + charrev
outcharlog = localdatapath + charlog

# Delete output files if already exists
files = [outcharlog, outcharenf, outcharrev]
for f in files:
	try:
	    os.remove(f)
	except OSError:
	    pass

print('\r')
print('>>> Beginning')

# Define variable names for the output files
evarnames = ['Charity Web ID', 'Enforcement', 'Enforecment Date', 'Summary', 'Variation', 'Variation Date', 'Report']
rvarnames = ['Charity Web ID', 'Effective Date', 'Status']
lvarnames = ['timestamp', 'Charity Web ID', 'url', 'status code', 'execution time']

# Write headers to the output files
with open(outcharenf, 'a', newline='\n') as f:
	writer = csv.writer(f, evarnames)
	writer.writerow(evarnames)

with open(outcharrev, 'a', newline='\n') as f:
	writer = csv.writer(f, rvarnames)
	writer.writerow(rvarnames)	

with open(outcharlog, 'a', newline='\n') as f:
	writer = csv.writer(f, lvarnames)
	writer.writerow(lvarnames)


#######################################################

######### Charity Enforcement Details Scrape ##########

#######################################################	

# Read in list of charity API ids
with open(incharweb, 'rb') as f:
	df = pd.read_csv(f)
	print(df.dtypes)
	print(df.shape)

# Drop observations without a valid web id
df = df[df.Note != "Likely an invalid ABN"]
print(df.shape)


# Extract API ids as a list
id_list = df['Charity Web ID'].tolist()
#print(id_list)


# Extract random sample for testing
#test_list = random.sample(id_list, 200)
#print(test_list)

# Define a counter to track how many elements of the list the script processes
counter = 1


# Loop through list of charity numbers and scrape info from webpages
for charid in id_list:
 
	starttime = dt.now() # Track how long it takes to scrape data for each charity

	webadd = 'https://www.acnc.gov.au/charity/' + str(charid) # Web address of charity's details
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

			# Registration and Revocation Details #

			revdetails = soup_org.find('div', {'class': 'field field-name-acnc-node-charity-status-history field-type-ds field-label-hidden'})

			if soup_org.find('div', {'class': 'group-info field-group-div'}): # If charity is part of a group
				print('No registration and revocation history - group charity')
				with open(outcharrev, 'a', newline='') as f:
					row = charid, 'NULL - GROUP', 'NULL - GROUP'
					writer = csv.writer(f)
					writer.writerow(row)		

			elif revdetails.find('div', {'class': 'view-empty'}): # If there is no registration history
				print('No registration and revocation history')
				with open(outcharrev, 'a', newline='') as f:
					row = charid, 'NULL', 'NULL'
					writer = csv.writer(f)
					writer.writerow(row)

			elif revdetails.find('div', {'class': 'view-content'}):
				print('Has registration and revocation history')
				revcontent = revdetails.find('div', {'class': 'view-content'})

				revtable = revcontent.find('tbody').find_all('tr')
				#print(len(revtable))
				for row in revtable:
					td_list = row.find_all('td')
					# Get relevant tds and write to output file
					revdate = td_list[0].text.strip() # Effective date
					revstatus = td_list[1].text.strip() # Status
					row = charid, revdate, revstatus
					print(row)	
					with open(outcharrev, 'a', newline='') as f:
						writer = csv.writer(f)
						writer.writerow(row)

			else: # Couldn't find enforcement details
				print('Could not find registration information on webpage')
				with open(outcharrev, 'a', newline='') as f:
					row = charid, 'NULL', 'NULL'
					writer = csv.writer(f)
					writer.writerow(row)

			# Enforcement Details # 

			enfdetails = soup_org.find('div', {'class': 'field field-name-acnc-node-charity-compliance-history field-type-ds field-label-hidden'})

			if enfdetails.find('div', {'class': 'view-empty'}): # If there is no enforcement history
				print('No enforcement history')
				with open(outcharenf, 'a', newline='') as f:
					row = charid, 'NULL', 'NULL', 'No enforcement history', 'NULL', 'NULL', 'NULL'
					writer = csv.writer(f)
					writer.writerow(row)

			elif enfdetails.find('div', {'class': 'view-content'}):
				print('Has enforcement history')
				enfcontent = enfdetails.find('div', {'class': 'view-content'})
				#print(enfcontent)

				enftable = enfcontent.find('tbody').find_all('tr')
				#print(len(enftable))
				for row in enftable:
					td_list = row.find_all('td')
					# Get relevant tds and write to output file
					enftype = td_list[0].text.strip() # Type of enforcement
					enfdate = td_list[1].text.strip() # Date of enforcement
					enfsummary = td_list[2].text.strip() # Text summary of enforcement
					enfvar = td_list[3].text.strip() # Variation in enforcement
					enfvardate = td_list[4].text.strip() # Date of variation in enforcement
					enfrep = td_list[5].find('a').get('href') # Link to enforcement report
					row = charid, enftype, enfdate, enfsummary, enfvar, enfvardate, enfrep
					print(row)	
					with open(outcharenf, 'a', newline='') as f:
						writer = csv.writer(f)
						writer.writerow(row)

			else: # Couldn't find enforcement details
				print('Could not find enforcement information on webpage')
				with open(outcharenf, 'a', newline='') as f:
					row = charid, 'NULL', 'NULL', 'Could not find enforcement information on webpage', 'NULL', 'NULL', 'NULL'
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
		with open(outcharlog, 'a', newline='') as f:
			writer = csv.writer(f)
			writer.writerow([dt.today().strftime('%Y%m%d %H:%M'), charid, webadd, rorg.status_code, runtime])			
				

print('\r')
print('>>> Finished')