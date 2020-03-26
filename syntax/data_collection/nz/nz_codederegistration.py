# Code deregistartion reasons
# Alasdair Rutherford
# Created: 3 April 2018
# Edited: Github history - https://github.com/DiarmuidM/mission_accomp/tree/master/syntax/data_collection/nz
# Edited by Tom Wallace
# This code takes a list of free text deregistration reasons (from column M of input file) and returns tuple of [Act Section, Reason Category] for each reason. 

#######Import packages#######
import re
import csv
import sys
import os
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import longtime
from loggenerator import gen_log

#######Initialization#######
datapath = './data_raw/' # Set data path

log_starttime = longtime() # When the script starts for the logfile

#######Functions#######
# Define function for coding deregistration reasons
def reasoncoding(reason):

	pattern31 = re.compile('(31)(\s)?(\(.\)(\s)?\((.)\))') # Match act references
	pattern32 = re.compile('(32)(\s)?(\(.\)(\s)?\((.)\))') # Match act references
	pattern40 = re.compile('(40)(\s)?(\(.\)(\s)?\((.)\))') # Match act references

	reasondict={}
	reasondict['windup'] = 0
	reasondict['parent'] = 0
	reasondict['failedfile'] = 0
	reasondict['merger'] = 0
	reasondict['duplicate'] = 0
	reasondict['request'] = 0	
	reasondict['section'] = 0	
	reasondict['act31']=''
	reasondict['act32']=''
	reasondict['act40']=''

	# Look for mentions of Section 31
	match31 = re.search(pattern31, reason)
	if match31:
		reasondict['act31'] = match31.group().replace(' ', '')

	# Look for mentions of Section 32
	match32 = re.search(pattern32, reason)
	if match32:
		reasondict['act32'] = match32.group().replace(' ', '')

	# Look for mentions of Section 40
	match40 = re.search(pattern40, reason)
	if match40:
		reasondict['act40'] = match40.group().replace(' ', '')

	# Look for mergers
	for term in ['merg', 'Merg' 'Amalgamated', 'amalgamated']:
		reasondict['merger'] += reason.find(term)>=0

	# Look for duplicate records
	for term in ['duplicat', 'Duplicat']:
		reasondict['duplicate'] += reason.find(term)>=0

	# Look for voluntary removal requests
	for term in ['request', 'Request', 'no longer wish', 'voluntary', 'Voluntary']:
		reasondict['request'] += reason.find(term)>=0			

	# Look for winding up / cease to operate / dissolution
	for term in ['liquid', 'wound up', 'wind up', 'winding up', 'wound-up', 'no longer operat', 'no longer active', 'cease', 'closed', 'never operate', 'dissolved', 'no longer functioning']:
		reasondict['windup'] += reason.find(term)>=0

	# Look for parent / umbrella transfers
	for term in ['parent', 'umbrella']:
		reasondict['parent'] += reason.find(term)>=0

	# Look for less structured mentions of the Act
	for term in ['section', 'Section']:
		reasondict['section'] += reason.find(term)>=0			

	# Look for failures to file or comply
	for term in ['failed to file', 'Failed to file', 'failure to file', 'failure  to file', 'meet its obligations', ]:
		reasondict['failedfile'] += reason.find(term)>=0

	# List all reasons that are uncoded
	if reasondict['windup']==0 and reasondict['parent']==0 and reasondict['merger']==False and reasondict['failedfile']==0 and reasondict['request']==0 and reasondict['duplicate']==0 and reasondict['section']==0 and reasondict['act32']=='' and reasondict['act40']=='':
		print('Uncoded reasons:',reason) # This returns 'Failed to lodge submission  with the High Court of New Zealand to appeal deregistration' Not sure if this should be added to the codes?


	# Create flags for analysis file
	actsection = 'Unspecified'
	if reasondict['act32'] != '':
		actsection = reasondict['act32']
	elif reasondict['act40'] != '':
		actsection = reasondict['act40']
	elif reasondict['act31'] != '':
		actsection = reasondict['act31']			
	elif reasondict['section']>0:
		actsection = 'Section' 

	deregreason = 'No further detail'
	if reasondict['windup']>0:
		deregreason = 'Wound up'
	elif reasondict['failedfile']>0:
		deregreason = 'Failed to file'	
	elif reasondict['merger']>0:
		deregreason = 'Merger'
	elif reasondict['request']>0:
		deregreason = 'Removed by Request'
	elif reasondict['parent']>0:
		deregreason = 'Parent'
	elif reasondict['duplicate']>0:
		deregreason = 'Removed due to Duplicate'											

	return [actsection, deregreason]	

#######Main program#######
# Specify the source file for the deregistration reasons
inputfilepath = datapath + 'Organisations/' + 'nz_Organisations_y0_m0_p0_integrity.csv'

# Output file to save the appended reasons
outputfilepath = datapath + 'Organisations/' + 'nz_orgs_deregreasons_integrity.csv'

with open(inputfilepath, 'r', newline='', encoding='utf-8') as inCSVfile:

	reader = csv.reader(inCSVfile)

	with open(outputfilepath, 'w', newline='', encoding='utf-8') as outCSVfile:

		writer = csv.writer(outCSVfile)
		fieldnames = next(reader)
		writer.writerow(fieldnames + ['dereg_act', 'dereg_reason'])

		for row in reader:
			if row[12] !='null':	# Column 13 'M' is dregistration reason
				# Reason is coded as a tuple of Act and text reason
				codetuple = reasoncoding(row[12])
				print(codetuple)
			else:
				codetuple = ['.', '.']
			writer.writerow(row + codetuple)

#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'This script takes deregistration field (column M "Deregistrationreasons") from nz_Organisations_y0_m0_p0_integrity.csv, which are free text, and extracts the reason and which part of legislation this relates to as two new columns.'
processedfiles = inputfilepath # Get the input file details
writtenfiles = outputfilepath # Get list of created files
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles) # Pass info to log file generator

print('\nAll done!')
