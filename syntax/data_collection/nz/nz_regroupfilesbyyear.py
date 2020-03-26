# Script to sort the large NZ Charities files into smaller files by year
# Alasdair Rutherford, Diarmuid McDonnell
# Created: 29 March 2018
# Last edited: Github history - https://github.com/DiarmuidM/mission_accomp/tree/master/syntax/data_collection/nz
# Edited by Tom Wallace
# Because of download limmitations of the API the larger files had to be downloaded in chunks. This file re-combines the chunked files for 'vOfficerOrganisations' and 'GrpOrgAllReturns'.

# Data guide: https://www.charities.govt.nz/charities-in-new-zealand/the-charities-register/open-data/

#######Import packages#######
import csv
import re
import requests
import os
import os.path
import errno
from time import sleep
import sys
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import downloaddate, longtime
from nz_rowfixer import row_fixer
from loggenerator import gen_log

#######Toggles#######
stata = True

#######Initialization#######
# Run the downloaddate function to get the date
ddate = downloaddate()

log_starttime = longtime() # When the script starts for the logfile

# Path to save the downloaded data
datapath = './data_raw/' # Dropbox folder for project

# Variables to store OData endpoint and database tables #

# Add $returnall=true to every url
baseurl = 'http://www.odata.charities.govt.nz/'

register = 'Organisations' # This is returned as xml due to the number of records - $returnall=true
grpannreturns = 'GrpOrgAllReturns'
 #'GrpOrgAllReturns?$returnall=true' # This is returned as xml due to the number of records - $returnall=true
activities = 'Activities'
area = 'AreaOfOperations'
beneficiaries = 'Beneficiaries'
group = 'Groups'
officers = 'Officers'
sectors = 'Sectors'
funds = 'SourceOfFunds'
vorgs = 'vOrganisations'
voff = 'vOfficerOrganisations'

#######Functions#######
# Split the downloaded annual return files into calendar years
processedfiles=[]
def splitfilesbyyear(filename, data, column, length, width, splityear=0, splitmonth=0, splitday=0, splitemp=0, spliteymonth=0):

	inputfilepath = datapath + '/' + data + '/' + 'nz_' + data + '_y' + str(splityear) + '_m' + str(spliteymonth) +  '_p' + str(splitemp) + '.csv'
	processedfiles.append(inputfilepath)
	with open(inputfilepath, 'rb') as file:
		filedata = file.read()

		# Replace the target string
	pattern = re.compile(b'[^\x00-\x7F]')
	filedata = re.sub(pattern, b'_', filedata) #filedata.replace('[^\x00-\x7F]', '_')

		# Write the file out again
	with open(datapath + '/' + 'nz_temp.csv', 'wb') as file:
		file.write(filedata)

	outputfiles = {}

	for year in range(2007,2020):
		outputfiles[str(year)] = open(filename + str(year) + '.csv', 'a', newline='')
		outputfiles[str(year) + 'a'] = csv.writer(outputfiles[str(year)])

	outputfiles['error'] = open(filename + 'error' + '.csv', 'a', newline='')
	outputfiles['errora'] = csv.writer(outputfiles['error'])

	with open(datapath + '/' + 'nz_temp.csv', 'r', newline='') as inCSVfile:
		reader = csv.reader(inCSVfile)
		print('-')
		print(inputfilepath)

		startrow = 1
		rowcounter=0
		while rowcounter<startrow:
			next(reader)
			rowcounter+=1

		for row in reader:
			#if len(row)==width: # this was the simple check before the function was written, can swtich back to it by commenting out the 2 lines below if the fixer breaks things
			out_row, fixed = row_fixer(row, width)
			if fixed==True:
				try:
					yearend = out_row[column][len(out_row[column])-length:]	# Take the year out of the YearEnded column
					year = int(yearend)
					#yearend = yearend[2 - len(yearend):]
					if year>=0 and year <=20: 
						yearend = '20' + yearend
					elif year >20 and year<=99:
						yearend = 2000
				except:
					yearend=0
			#print(inputfilepath, rowcounter)
			#print('		', row[column], '  |  -', yearend, '-')
			else:
				yearend=0

			# Rceode the missing values for Stata
			if stata == True:
				out_row = [x if x != 'Null' else '.' for x in out_row]

			if int(yearend) in range(2007, 2020): # ['2007', '2008', '2009', '2010', '2011', '2012', '2013', '2014', '2015', '2016', '2017']:
				outputfiles[str(yearend) + 'a'].writerow(out_row)
				#print('.', end='')
			else:
				outputfiles['errora'].writerow(out_row)
				#print('*', end='')
			rowcounter+=1

	for year in range(2008,2018):
		outputfiles[str(year)].close()

	outputfiles['error'].close()

# Creates the header rows for the files by year
def createannreturnfiles(filename, source):
	with open(source, 'r', newline='') as inCSVfile:
		reader = csv.reader(inCSVfile)
		row = reader.__next__()

	for year in range(2007,2020):
		outputfile = open(filename + str(year) + '.csv', 'w', newline='')
		outputfilew= csv.writer(outputfile)
		outputfilew.writerow(row)
		outputfile.close()
		
	outputfile = open(filename + 'error' + '.csv', 'w', newline='')
	outputfilew= csv.writer(outputfile)
	outputfilew.writerow(row)
	outputfile.close()

	return len(row)

#######Main program#######
search = []
search_big = [voff, grpannreturns] # []
writtenfiles=[]

for data in search_big:

	filename = datapath + '/' + data +'/' + data + '_yr'
	# nz_vOfficerOrganisations_y2017_m0_p0_20180330.csv

	for year in range(2007,2020): # This loop creates the output names manually for the log file so it will need updated when 2020 is added - it was taking too long to make automatic but it could be done
		writtenfiles.append(filename+str(year)+'.csv')
	writtenfiles.append(filename+'error'+'.csv')

	filewidth = createannreturnfiles(filename, datapath + '/' + data + '/' + 'nz_' + data + '_y2017' + '_m0' +  '_p0' + '.csv')

	print('Organise', data, 'by year')

	for year in [2008]:
		if data == grpannreturns:
			print('')
			print('grpannreturns', year)
			for month in range(1,13,1):
				splitfilesbyyear(filename, data, 103, 4, filewidth, splityear=year, spliteymonth=month, splitemp=1) # Using column 103 (index from 0) 'CZ' to regroup the files 'YearEnded'
				splitfilesbyyear(filename, data, 103, 4, filewidth, splityear=year, spliteymonth=month, splitemp=2)
		elif data == voff:
			print('')
			print('voff')
			for month in range(1,13,1):
				splitfilesbyyear(filename, data, 14, 2, filewidth, splityear=year, spliteymonth=month) # Using column 14 (index from 0) 'O' to regroup the files 'PositionAppointmentDate'
				#logcsv.writerow([datetime.today().strftime('%Y%m%d %H:%M'), filename, searchurl, success, fails])				# record in logfile

	for year in [2007, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017]:
		if data == grpannreturns:
			print('')
			print('grpannreturns', year)
			splitfilesbyyear(filename, data, 103, 4, filewidth, splityear=year)	
		elif data == voff:
			print('')
			print('voff', year)
			splitfilesbyyear(filename, data, 14, 2, filewidth, splityear=year)		# Get csv

	print('')
	print('Done sorting ' + data)
	print('------------------------------------------------------------------------------')

os.remove(datapath + '/' + 'nz_temp.csv')
print('Removed temp file:',datapath + '/' + 'nz_temp.csv')

#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'Because of download limmitations of the API the larger files had to be downloaded in chunks. This file re-combines the chunked files for "vOfficerOrganisations" and "GrpOrgAllReturns".'
processedfiles = processedfiles # Get the input file details
writtenfiles = writtenfiles # Get list of created files WARNING: this list has been created manually and will not update in future years
settings_toggles = {'stata': stata}
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generator

print('\nAll done!')