## Python script to download monthly snapshot of England and Wales Register of Charities and SIR data:

# Diarmuid McDonnell
# Created: 28 March 2018
# Last edited: captured in Github file history
# Edited by Tom Wallace

#######Set path#######
projpath = './' # Set the base path and all other paths branch off it

#######Global params#######
waitsleep = 60  # Set the time the scraper waits if it fails, in seconds

#######Import packages#######
import json
import csv
import re
import sys
import requests, zipfile, io
import os
import os.path
import errno
import urllib
from time import sleep
from bs4 import BeautifulSoup
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import downloaddate, longtime
from fimport import import_zip # Moved to top so all imports are togethor
from loggenerator import gen_log

#######Program#######
starttime = longtime() # Grab start time for the log file
# Run the downloaddate function to get the date 'ew_download.py' was executed. Used to construct dirs for data
ddate = downloaddate()

# Define urls where Charity Registers can be downloaded #
main_url = 'http://data.charitycommission.gov.uk/default.aspx' # returns Data download webpage

# Request data from urls #
r = requests.get(main_url, allow_redirects=True)
soup = BeautifulSoup(r.text, 'html.parser')
#print(soup)

links = soup.find_all('a')
#print(links)

dlinks = soup.select("a[href*=extract1]")
#print(dlinks) # Now I have a list of all of the a href elements we need.
#print(len(dlinks))
numfiles = len(dlinks)
months = numfiles / 3
print('Host has %s months of data extracts in total. Getting most recent.' %int(months))

# We only want the first three links as this corresponds to the most recent month of data.
latest_dlinks = dlinks[0:3]
#latest_dlinks = dlinks[3:6] - the file generalises to other months
#print(latest_dlinks)
file_type = ['CharityRegister', 'SIR', 'TableBuild']
counter = 0

log_output_filename = []
for el in latest_dlinks:
	link = el['href'] # Extract the href part of the <a> element.
	print('\nGrabbing:',link)
	print('Please wait...')

	# Request the link and unzip to the correct folder
	req = requests.get(link, allow_redirects=True)
	statcode = 0
	try:
		statcode = req.status_code
	except:
		pass
	error_count = 0
	while statcode != 200:
		try:
			print(">>> Bad status code: " + statcode + " <<<") # I want to take this information and use it to name the files and folders
		except:
			print(">>> No status code returned <<<")
		print(">>> Sleeping " + str(waitsleep) + " seconds before trying again <<<")
		sleep(waitsleep)
		req = requests.get(link, allow_redirects=True)
		error_count = error_count+1
		if error_count==5:
			print(">>> Multiple failures, check source site is up. Killing script. <<<")
			exit()
	else:
		print('Status code:',req.status_code) # I want to take this information and use it to name the files and folders
		pass

	metadata = req.headers
	#print(metadata)
	#print(type(metadata))
	lastmod = metadata['Last-Modified']
	print('Dataset was last modified (by NCVO):',lastmod)
	#print(len(lastmod))
	try:
		udate = re.search('\d\d(.+?)\d\d:\d\d:\d\d', lastmod).group(1) # Grab the date with regex, should be robust to some changes in format
		udate = udate.replace(' ','')
	except:
		print('>>> Date error <<<')
		udate = 'date_error'
	#print(udate) # Last modified date

	# Create a folder for the download to be saved in #
	filename = os.path.basename(__file__) # Get the current filename as a variable
	filename = filename.replace('.py','/') # Replace extension with filepath / for concatination

	rawdatapath = projpath + filename + udate + '/data_raw' # Put 'data_raw' in a folder named after the script
	if not os.path.exists(rawdatapath):
	    os.makedirs(rawdatapath)

	extractdatapath = projpath + filename + udate + '/data_extracted' # Put 'data_clean' in a folder named after the script
	if not os.path.exists(extractdatapath):
	    os.makedirs(extractdatapath)

	# Write the r.content to a file in the newly created folder #
	name = file_type[counter]

	file_name = 'cc_' + name + '_' + ddate + '.zip'
	file = rawdatapath + '/' + file_name
	#print(file)
	log_output_filename.append(file)

	outzip = open(file, 'wb')
	outzip.write(req.content)
	outzip.close()

	# Unzip the files using fimport.py #

	if name == 'CharityRegister': 
		import_zip(file)
		counter +=1

	else:
		print('Not unzipping this file and moving onto the next\n')
		counter +=1

#Log file here
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'Downloads BCP data files for most recent month from http://data.charitycommission.gov.uk/default.aspx. Then calls fimport.py to unzip and conver them.'
processedfiles = main_url # Get the input file details
writtenfiles = log_output_filename # Get list of created files
settings_toggles = {'waitsleep': waitsleep}
gen_log(starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generator

print('\n-----------------------')
print('                       ')
print('Finished downloading and unzipping latest copy of Charity Register.')

############################################################################################################


# End of data download #
############################################################################################################