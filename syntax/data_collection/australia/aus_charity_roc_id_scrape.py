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


r = requests.get("https://www.acnc.gov.au/charity?name_abn%5B0%5D=11002058127")
r.status_code

# Define functions #

# Download Register of Charities

def roc_download(outpath, ddate): # takes two arguments - location for saving file, and download date
    #
    # `ddate' can take any format (e.g. YYYYMMDD) as long as there are no spaces
    #
    
    print('Downloading Charity Register')
    print('\r')
    
    reg = requests.get('https://data.gov.au/data/dataset/b050b242-4487-4306-abf5-07ca073e5594/resource/eb1e6be4-5b13-4feb-b28e-388bf7c26f93/download/datadotgov_main.xlsx') # Search for all charities
    print(reg.status_code, reg.headers)
    
    # Write the reg.content to a file
    
    outfile = outpath + 'datadotgov_main_' + str(ddate) + '.xlsx' # Charity Register
    
    with open(outfile, 'wb') as f:
        f.write(reg.content)
    
    print('\r')    
    print('Successfully downloaded Charity Register')



# Collect ACNC web ids for charities
    
def webid_download(regid, outpath, logpath, ddate):
    #
    # `ddate' can take any format (e.g. YYYYMMDD) as long as there are no spaces
    #
    
    print('Downloading charity web ids')
    print('\r')
    
    webadd = 'https://www.acnc.gov.au/charity?name_abn%5B0%5D=' + str(regid)
		
	# Define counter to track number of webpage request attempts; try three times
	
    attempt = 1

    while attempt < 4:
        starttime = dt.now()

        rorg = requests.get(webadd) # Grab the page using the URL
		
        if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
            attempt = 5
            html_org = rorg.text # Get the text elements of the page.
            soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.

            if soup_org.find('td', {'class': 'views-field views-field-acnc-search-api-title-sort'}):
                charlinkdetails = soup_org.find('td', {'class': 'views-field views-field-acnc-search-api-title-sort'})
							
                if charlinkdetails.text != '':
                    charname = charlinkdetails.text.lstrip()
                else:
                    charname = 'NULL'
                    
                charlink = charlinkdetails.find('a').get('href')
                webid = charlink[9:] # ignore string "charity"
                url = 'https://www.acnc.gov.au/charity/' + webid
                    
                row = regid, charname, webid, url # define an observation
                    
                outfile = outpath + 'aus_id_scrape_' + str(ddate) + '.csv' # List of charities and their website search ids
                with open(outfile, 'a', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(row)
                    
                    success = 1 # successful scrape
                    attempt = 5 # set value higher than 3 so script doesn't fall into "else" clause
    
            else:
                print('Could not find id on webpage')
    
                row = regid, 'NULL', 'NULL'
    
                outfile = outpath + 'aus_id_scrape_' + str(ddate) + '.csv' # List of charities and their website search ids
                with open(outfile, 'a', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow(row)
    	            				
        else:
            print('\r')
            print(rorg.status_code, '| Could not resolve address of webpage')
            print('Will try to request webpage a couple more times')
            attempt +=1
            success = 0
    
    	# Export results of script to log file
    
        runtime = dt.now() - starttime # track how long it took to process the scrape
        logfile = logpath + 'aus_id_scrape_log_' + ddate + '.csv'
        with open(logfile, 'a', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([dt.today().strftime('%Y%m%d %H:%M'), str(regid), str(webadd), str(webadd), success, attempt, rorg.status_code, runtime]) 


#######################################################

############## Preliminaries ##############

#######################################################	

# Get the current date

ddate = dt.now().date()

# Define paths

#localdatapath = 'C:/Users/mcdonndz-local/Dropbox/aus_charity_data/data_raw/'
localdatapath = '/home/diarmuidmc/environments/mission_accomp/data/aus/'
projpath = './' # Location of syntax

# Define file names and output paths

charreg = 'datadotgov_main_' + str(ddate) + '.xlsx' # Charity Register
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


# Write headers to log files #

logfile = logpath + 'aus_id_scrape_log_' + ddate + '.csv'
idlogvarnames = ['started_scrape', 'regid', 'webadd', 'success', 'attempts', 'status code', 'execution time']
with open(logfile, 'w') as f:
    writer = csv.writer(f, idlogvarnames)
    writer.writerow(idlogvarnames)


#######################################################

########### Annual Information Statements #############

#######################################################	

# Define urls where datasets can be found

aisdata = ['https://data.gov.au/data/dataset/a1f8626c-fefb-4c4d-86ea-deaa04fb1f6e/resource/8d020b50-700f-4bc4-8c78-79f83d99be7a/download/datadotgov_ais17.xlsx', 
	'https://data.gov.au/data/dataset/7e073d71-4eef-4f0c-921b-9880fb59b206/resource/b4a08924-af4f-4def-96f7-bf32ada7ee2b/download/datadotgov_ais16.xlsx', 
	'https://data.gov.au/dataset/86cad799-2601-4f23-b02c-c4c0fc3b6aff/resource/569b8e48-a0ad-4008-9d95-7f91b6cfa2aa/download/20181011_datadotgov_ais15.xlsx', 
	'https://data.gov.au/dataset/d7992845-5d3b-4868-b012-71f672085412/resource/4d65259d-1ccf-4c78-a223-e2bd49dc5fb1/download/20181011_datadotgov_ais14.xlsx', 
	'https://data.gov.au/dataset/cc9d8524-39d8-4374-84b9-20e9d1070e82/resource/ce8bf129-9525-4353-a747-d89d8d4b5cc6/download/20181011_datadotgov_ais13.xlsx']

aisgrpdata = ['https://data.gov.au/data/dataset/a1f8626c-fefb-4c4d-86ea-deaa04fb1f6e/resource/8a18e71a-58d1-414f-adee-c9066560b05c/download/acnc-2017-group-ais-dataset-approved-reporting-groups.xlsx', 
				'https://data.gov.au/data/dataset/7e073d71-4eef-4f0c-921b-9880fb59b206/resource/8932e61f-0124-48ac-b3be-f3e49f03b33f/download/group-ais16-datagov-final.xlsx',
				'https://data.gov.au/dataset/86cad799-2601-4f23-b02c-c4c0fc3b6aff/resource/3d57d625-b183-4677-85b1-009b2000ed02/download/2015-ais-group-registered-charities.xls',
				'https://data.gov.au/dataset/d7992845-5d3b-4868-b012-71f672085412/resource/b3b49610-7f47-41b2-9350-49b7fd8acd93/download/2014-ais-data-for-group-reporting-charities.xlsx']


# 2013-2017 AIS #

print('Downloading 2017-2013 returns')
print('\r')

year = 2017
for d in aisdata:

	ais = requests.get(d) # Search for all charities
	print(ais.status_code, ais.headers)

	# Write the r.content to a file in the newly created folder
	outputfile = localdatapath + 'aus_ais_' + str(year) + '.xlsx'
	print(outputfile)
	outcsv = open(outputfile, 'wb')
	outcsv.write(ais.content)
	outcsv.close()
	year -=1
	print('\r')
	print('Successfully downloaded ', str(year), ' annual information statement')

print('\r')
print('Successfully downloaded all annual information statements')	


# Group Returns #

print('Downloading group returns')
print('\r')

year = 2017
for d in aisgrpdata:

	ais = requests.get(d) # Search for all charities
	print(ais.status_code, ais.headers)

	# Write the r.content to a file in the newly created folder
	outputfile = localdatapath + 'aus_ais_group-returns_' + str(year) + '.xlsx'
	print(outputfile)
	outcsv = open(outputfile, 'wb')
	outcsv.write(ais.content)
	outcsv.close()
	year -=1

print('\r')
print('Successfully downloaded group returns')	


#######################################################

############## Charity Register Download ##############

#######################################################	


# Call on the function for downloading the Register of Charities #
#
# Note that you must define the two parameters before calling the function - see code below:
#

# outpath = '/location/where/you/want/file/saved/'
# ddate = 'YYYY-MM-DD'

roc_download(outpath, ddate) # execute function


#######################################################

########### Charity Details Website Scrape ############

#######################################################	
'''
	# The regulator's website uses ids instead of charity numbers when searching for records.
	# Therefore, the code below takes the charity numbers from the Register and searches 
	# the regulator's website for their ids.
'''

webid_download('11002058127', outpath = 'C:/Users/t95171dm/Desktop/tmp/', 
               logpath = 'C:/Users/t95171dm/Desktop/tmp/', ddate = '20200128')


# Read in list of charity ids
with open(outcharreg, 'rb') as f:
	df = pd.read_excel(f)
	print(df.dtypes)

# Extract ids as a list
id_list = df['ABN'].tolist()
#print(id_list[0:1000])
del df

# Define variable names for the output files
varnames = ['ABN', 'Charity Name', 'Charity Web ID', 'URL']
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

				
		

print('Finished scraping website ids')

print('\r')
print('>>> Finished')