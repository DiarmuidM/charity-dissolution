# Script to search and download Charity Register from ACNC API and annual returns submitted to ACNC 2013 onwards
# Diarmuid McDonnell
# Created: 26 February 2018
# Last edited: captured in Github file history

# Import packages #

from bs4 import BeautifulSoup as soup
from datetime import datetime as dt
import requests
import pandas as pd
import csv
import os


#######################################################

############## Preliminaries ##############

#######################################################	

# Get the current date

ddate = dt.now().date()

# Define paths

localdatapath = '/home/diarmuidmc/environments/mission_accomp/data/aus/'
#localdatapath = 'C:/Users/mcdonndz-local/Dropbox/aus_charity_data/data_raw/'
projpath = './' # Location of syntax

# Define file names and output paths

charreg = 'remids_20190830.xlsx' # Charity Register - only orgs without a webid
charweb = 'auscharities_web-ids_' + str(ddate) + '.csv' # List of charities and their website search ids
charlog = 'auscharities_web-ids_log_' + str(ddate) + '.csv' # Log file recording the success of the script

outcharreg = localdatapath + charreg
outcharweb = localdatapath + charweb
outcharlog = localdatapath + charlog

# Delete output files if already exists
files = [outcharlog, outcharweb]
for f in files:
	try:
	    os.remove(f)
	except OSError:
	    pass

print('\r')
print('>>> Beginning')

#######################################################

########### Charity Details Website Scrape ############

#######################################################	
'''
	# The regulator's website uses ids instead of charity numbers when searching for records.
	# Therefore, the code below takes the charity numbers from the Register and searches 
	# the regulator's website for their ids.
'''

# Read in list of charity ids
with open(outcharreg, 'rb') as f:
	df = pd.read_excel(f)
	print(df.dtypes)

# Extract ids as a list
id_list = df['ABN'].tolist()
print(id_list[0:1000])
del df

# Define variable names for the output files
varnames = ['ABN', 'Charity Name', 'Charity Web ID']
lvarnames = ['timestamp', 'ABN', 'url', 'status code', 'execution time']

with open(outcharweb, 'a', newline='\n') as f:
	writer = csv.writer(f, varnames)
	writer.writerow(varnames)

with open(outcharlog, 'a', newline='\n') as f:
	writer = csv.writer(f, lvarnames)
	writer.writerow(lvarnames)

# Define a counter to track how many rows of the input file the script processes
counter = 1

# Loop through list of charity numbers and scrape info from webpages
for ccnum in id_list: 
 
	starttime = dt.now() # Track how long it takes to scrape data for each charity

	webadd = 'https://www.acnc.gov.au/charity?name_abn%5B0%5D=' + str(ccnum)
		
	# Define counter to track number of webpage request attempts; try three times
	attempt = 1

	while attempt < 4:

		rorg = requests.get(webadd) # Grab the page using the URL
		
		if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
			attempt = 5
			html_org = rorg.text # Get the text elements of the page.
			soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

			if soup_org.find('td', {'class': 'views-field views-field-acnc-search-api-title-sort'}):
				charlinkdetails = soup_org.find('td', {'class': 'views-field views-field-acnc-search-api-title-sort'})
				charname = charlinkdetails.text # Get name of charity
				
				# Deal with instances where charityname==""
			
				charname = charname.lstrip()
				#print(type(charname))
				
				charlink = charlinkdetails.find('a').get('href')
				#print(charlink) # now extract the unnecessary text (i.e. '/charity/')
				charlink = charlink[9:]
				print(charlink)

				with open(outcharweb, 'a', newline='\n') as f:
					writer = csv.writer(f)
					row = ccnum, charname, charlink, 'Successful'
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
				print('Could not find id on webpage')
				with open(outcharweb, 'a', newline='\n') as f:
					writer = csv.writer(f)
					row = ccnum, 'NULL', 'NULL', 'Likely an invalid ABN'
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
			writer.writerow([dt.today().strftime('%Y%m%d %H:%M'), ccnum, webadd, rorg.status_code, runtime])			
		

print('Finished scraping website ids')

print('\r')
print('>>> Finished')