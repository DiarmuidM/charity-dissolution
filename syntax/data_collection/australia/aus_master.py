## Project: Mission Accomplished? A Cross-national Examination of Charity Dissolution
## Created by: Diarmuid McDonnell
## Date: 18/05/2019

## Python master script that runs all of the data collection scripts for the Australia

from time import sleep
from downloaddate_function import downloaddate
from datetime import datetime
import dropbox
import csv


# Get today's date
ddate = downloaddate()	
print('The date and time is ' + datetime.now())

# Fetch Dropbox authentication
dbtokenpath = 'C:/Users/mcdonndz-local/Desktop/admin/db_token.txt'
#dbtokenpath_pi = '/home/pi/admin/dp_token.txt'
dbtokenfile = open(dbtokenpath, "r")
dbapitoken = dbtokenfile.read()
print(dbapitoken)

dbx = dropbox.Dropbox(dbapitoken) # Create an object for accessing Dropbox API

# Define paths
localdatapath = 'C:/Users/mcdonndz-local/Desktop/data/temp/'
remotelogpath = '/aus_charity_data/logs/' # Dropbox path
projpath = './' # Location of syntax

logfile = localdatapath + 'aus_charity_data_log_' + ddate + '.csv'

# Run python scripts in order #

# aus_charity_download.py
starttime = datetime.now()
try:
	import aus_charity_download.py
	runtime = datetime.now() - starttime 
	print('Finished executing aus_charity_download.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	success = 1
	sleep(10)
except:
	print('Could not execute aus_charity_download.py')
	success = 0
	runtime = datetime.now() - starttime
with open(logfile, 'a', newline='') as f:
	writer = csv.writer(f)
	writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), 'aus_charity_download.py', success, runtime])

# aus_trustee_scrape.py
starttime = datetime.now()
try:
	import aus_trustee_scrape.py
	runtime = datetime.now() - starttime 
	print('Finished executing aus_trustee_scrape.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	success = 1
	sleep(10)
except:
	print('Could not execute aus_trustee_scrape.py')
	success = 0
	runtime = datetime.now() - starttime
with open(logfile, 'a', newline='') as f:
	writer = csv.writer(f)
	writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), 'aus_trustee_scrape.py', success, runtime])	

# aus_enforcement_scrape.py
starttime = datetime.now()
try:
	import aus_enforcement_scrape.py
	runtime = datetime.now() - starttime 
	print('Finished executing aus_enforcement_scrape.py')
	print('                                             ')
	print('---------------------------------------------')
	print('                                             ')
	success = 1
	sleep(10)
except:
	print('Could not execute aus_enforcement_scrape.py')
	success = 0
	runtime = datetime.now() - starttime
with open(logfile, 'a', newline='') as f:
	writer = csv.writer(f)
	writer.writerow([datetime.today().strftime('%Y%m%d %H:%M'), 'aus_enforcement_scrape.py', success, runtime])	

# Upload files to Dropbox
inlogfile = logfile
outlogfile = remotelogpath + 'aus_charity_data_log_' + ddate + '.csv' # Log file

with open(inlogfile, 'rb') as f:
	dbx.files_upload(f.read(), outlogfile, mute=True, mode=dropbox.files.WriteMode.overwrite)	