# Script to search NZ Charities Services OData API
# Diarmuid McDonnell, Alasdair Rutherford
# Created: 27 February 2018
# Last edited: captured in Github file history
# Edited by Tom Wallace

# Data guide: https://www.charities.govt.nz/charities-in-new-zealand/the-charities-register/open-data/

#######Import packages#######
import csv
import re
import requests
import shutil
import os
import os.path
from time import sleep
from datetime import datetime
import sys
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import downloaddate, longtime
from loggenerator import gen_log

#######Toggles#######
# To perform full run from scratch these should all be set to 'True'
# Each toggle relies on the data from the last stage so will fail if it has not been previously run
download_toggle = False # Download data or not
regroup_toggle = False # Perform regroup of data which was too large to download as one file
integrity_toggle = False # Check integrity of data for broken columns
codeareas_toggle = False # Encodes areas of operation
deregistration_toggle = True # Encodes reason for deregistration

downloadsleep = 60*2 # Sleep time to wait after a failed download
wranglesleep = 10 # Time to wait between each of the processing scripts

#######Initialization#######
# Run the downloaddate function to get the date
ddate = downloaddate()

log_starttime = longtime() # When the script starts for the logfile
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get where the script is located, used by the log files

# Path to save the downloaded data

datapath = './data_raw/' # Dropbox folder for project

#######Functions#######
# Given the web address and a recordtype, this function downloads a CSV with specified splits
def downloadcsv(baseurl, data,  splityear=0, splitmonth=0, splitday=0, splitemp=0, spliteymonth=0):

	# Build the filters based on the search split
	recordfilter = ''
	if splityear>0:
		recordfilter = '&$filter=year(DateRegistered) eq ' + str(splityear)
	if splitmonth>0:
		recordfilter = recordfilter + ' and month(DateRegistered) ge ' + str(splitmonth) + ' and month(DateRegistered) lt ' + str(splitmonth + 1)
	if splitday>0:
		recordfilter = recordfilter + ' and day(DateRegistered) eq ' + str(splitday)
	if splitemp>0:
		recordfilter = recordfilter + ' and numberoffulltimeemployees mod 2 eq ' + str(splitemp - 1)
	if spliteymonth>0:
		recordfilter = recordfilter + ' and endofyearmonth eq ' + str(spliteymonth)
	
	# Write the r.content to a file in the newly created folder #
	outputfile = datapath + '/' + data + '/' + 'nz_' + data + '_y' + str(splityear) + '_m' + str(spliteymonth) +  '_p' + str(splitemp) + '.csv'
	print('		Saving CSV file to:', outputfile)

	# Build the query web address
	queryadd = baseurl + data + '?$returnall=true&$format=csv' + recordfilter
	print('		Request page:', queryadd, end='')
	sleep(1)

	# Make the request.  If it fails, try two further times.
	attempt = 1
	failures = 0
	while attempt<=3:
		try:
			# Stream the large csv straight to a downloaded file
			r = requests.get(queryadd, stream=True, allow_redirects=True)
			print('TYPE:',type(r.raw))
			with open(outputfile, 'wb') as f:
				shutil.copyfileobj(r.raw, f)
			attempt=5
			print('		Success!')
		except:
			print('		Failed on attempt', attempt, '| ', end='')
			failures+=1
			attempt+=1
			sleep(downloadsleep)
	success = attempt==5
                                                                              
	print('		---------------------------------------')

	return outputfile, queryadd, success, failures


#######Parameters#######
# Define url and data endpoints to search in

baseurl = 'http://www.odata.charities.govt.nz/'

register = 'Organisations' 
grpannreturns = 'GrpOrgAllReturns'
activities = 'Activities'
area = 'AreaOfOperations'
beneficiaries = 'Beneficiaries'
group = 'Groups'
officers = 'Officers'
sectors = 'Sectors'
funds = 'SourceOfFunds'
vorgs = 'vOrganisations'
voff = 'vOfficerOrganisations'

print('_____________________________________________')

#######Main program#######
writtenfiles=[]
if download_toggle == True:
	search = [activities, area, beneficiaries, group, sectors, funds, register, vorgs, officers] 
	search_big = [voff, grpannreturns] 

	if not os.path.exists(datapath):
	    os.makedirs(datapath)

	# Open logfile
	logfilepath = scriptpath + '\\Logs\\'
	if not os.path.exists(logfilepath):
	    os.makedirs(logfilepath)
	logfile = open(logfilepath + 'download_log_' + ddate + '.csv', 'w', newline='')
	logcsv = csv.writer(logfile)
	logcsv.writerow(['timestamp', 'filename', 'url', 'downloaded', 'failedattempts'])


	# Download all the small datasets
	for data in search:

		print('CSV - Whole files 	|	Record type:', data)

		# Create a folder for the record type
		try:
			os.mkdir(datapath+'/'+data)
			print(data, 'folder created')
		except:
			print(data, 'folder already exists')

		filename, searchurl, success, fails = downloadcsv(baseurl, data)		# Download the csv
		logcsv.writerow([datetime.today().strftime('%Y%m%d %H:%M'), filename, searchurl, success, fails])	# write to logfile
		writtenfiles.append(filename)

		print('Done searching for ' + data)
		print('_____________________________________________')
		print('')


	# Download all the large datasets
	for data in search_big:

		print('CSV - split in parts 	|	Record type:', data)

		# Create a folder for the record type
		try:
			os.mkdir(datapath+'/'+data)
			print(data, 'folder created')
		except:
			print(data, 'folder already exists')

		# Split years - 2008 includes most charities, so needs split up
		for year in [2008]:
			if data == grpannreturns:
				# print('grpannreturns')
				for month in range(1,13,1):
				#for month in range(3,4,1):
					filename, searchurl, success, fails = downloadcsv(baseurl, data, splityear=year, spliteymonth=month, splitemp=1)		# Get part one csv. FAILED here on m3 p1
					logcsv.writerow([datetime.today().strftime('%Y%m%d %H:%M'), filename, searchurl, success, fails])							# record in logfile
					writtenfiles.append(filename)
					filename, searchurl, success, fails = downloadcsv(baseurl, data, splityear=year, spliteymonth=month, splitemp=2)		# Get part two csv
					logcsv.writerow([datetime.today().strftime('%Y%m%d %H:%M'), filename, searchurl, success, fails])							# record in logfile
					writtenfiles.append(filename)
			elif data == voff:
				# print('voff')
				for month in range(1,13,1):
					filename, searchurl, success, fails = downloadcsv(baseurl, data, splityear=year, spliteymonth=month)		# Get csv
					logcsv.writerow([datetime.today().strftime('%Y%m%d %H:%M'), filename, searchurl, success, fails])				# record in logfile
					writtenfiles.append(filename)
			
		# The remaining years only need split by year
		for year in [2007, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017]: # Should this be 2018 now?
			filename, searchurl, success, fails = downloadcsv(baseurl, data, splityear=year)				# Get csv
			logcsv.writerow([datetime.today().strftime('%Y%m%d %H:%M'), filename, searchurl, success, fails])	# record in logfile
			writtenfiles.append(filename)

		print('')
		print('Done searching for ' + data)
		print('------------------------------------------------------------------------------')

	# Close the logfile and finish
	logfile.close()
	print('\nAll done!')
else:
	print('Download_toggle set to False, no data downloaded\n')

#######Data wrangling scripts#######
#These can be run as individual files
# Regroup downloaded files by year
if regroup_toggle == True:
	import nz_regroupfilesbyyear
	print('nz_regroupfilesbyyear.py - Successfully completed.')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(wranglesleep)

# Check integrity of downloaded files
if integrity_toggle == True:
	import nz_checkintegrity
	print('nz_checkintegrity.py - Successfully completed.')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(wranglesleep)

# Code area of operations variable
if codeareas_toggle == True:
	import nz_codeareas
	print('nz_codeareas.py - Successfully completed.')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	sleep(wranglesleep)

# Code deregistration variable
if deregistration_toggle == True:	
	import nz_codederegistration
	print('nz_codederegistration.py - Successfully completed.')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')

#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = scriptpath # Get the absolute dir the script is in
scriptdesc = 'This script downloads the data from the API and acts as a master file which can call the other scripts to process the data once it is downloaded. This logfile only relates to the data download, any other script called will generate its own logfile. The download also creates an additional "download_log_[date].csv" log file which contains more information on the download.'
processedfiles = None # Get the input file details
if download_toggle==True:
	writtenfiles = writtenfiles
else: 
	writtenfiles = None # Get list of created files
settings_toggles = {'download_toggle': download_toggle, 'regroup_toggle': regroup_toggle, 'integrity_toggle': integrity_toggle, 'codeareas_toggle': codeareas_toggle, 'deregistration_toggle': deregistration_toggle, 'downloadsleep': downloadsleep, 'wranglesleep': wranglesleep}
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generato

print('Everything all done!\n')