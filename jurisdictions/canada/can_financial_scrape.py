## Python script to download financial data
## of Canadian charities from the CRA website

# Diarmuid McDonnell, ALasdair Rutherford
# Created: 17 May 2018
# Last edited: captured in Github file history


import csv
import requests
import os
import os.path
import errno
import zipfile
import io
from time import sleep
import random

from bs4 import BeautifulSoup

from downloaddate_function import downloaddate

#prob dont need basic info or B
#in A need question 2 as it's the dependant  - make a note of this in the markdown
# grab the links to the sceduels before sraping into them  where neeeded - also have the links in the CSV

# ==========================================================

# ==========================================================

def buildwebadd(orgid, name):

	webadd = 'http://www.cra-arc.gc.ca/ebci/haip/srch/charity-eng.action?bn=' + orgid + '&m=1'

	return webadd


# This function looks at the charity page and finds the link to their T3010 record if it exists

def getT3010(webadd):

	trys = 0
	while trys<=3:
		try:
			rorg = requests.get(webadd)
			if rorg.status_code == 200:
				trys=5
			else:
				sleep(5)
		except:
			trys +=1
			sleep(5)

	print(webadd, ' | ', rorg.status_code)

	if rorg.status_code == 200:
		html_org = rorg.text
		soup_org = BeautifulSoup(html_org, 'html.parser')

		orgdetails = soup_org.find(text="T3010 Return")

		# If there is a T3010 link, then parse it
		if orgdetails != None:
			# Navigate up the tree to get at the <a> tage
			search = orgdetails.parent.parent.parent
			# Find the <a> tag, and look for the hyperlink
			link = search.find('a')
			if link.has_attr('href'):
				return 'http://www.cra-arc.gc.ca/' + link['href']
			else:
				print('No link')
				return False
		else:
			print('No link')
			return False
	else:
		print('| ************ Address did not resolve')
		return False


# Given a T3010 link, this function loops through the available years

def scrapeorg(webadd, orgid):

	print('--------------------------------------')

	trys = 0
	while trys<=3:
		try:
			rorg = requests.get(webadd)
			if rorg.status_code == 200:
				trys=5
			else:
				sleep(5)
		except:
			trys +=1
			sleep(5)
	#print(webadd, ' | ', rorg.status_code)

	if rorg.status_code == 200:

		html_org = rorg.text
		soup_org = BeautifulSoup(html_org, 'html.parser')

		# Build a table of all the available years
		yeartable = soup_org.find_all('div', class_=' ')
		# Loop through each year
		for year in yeartable:
			# Extract the financial year date
			findate = year.text[0:10]
			# Extract the financial year
			finyear = int(findate[0:4])
			# Extract the link to the return for that year
			finlink = 'http://www.cra-arc.gc.ca/' + year.find('a')['href']
			print(findate, end='')
			if finyear>=2009:
				# Pass the return for scraping
				scrape_finance(finlink, finyear, orgid, webadd)
			else:
				print(' | --')



# This function takes a given report, and finds the link to the Schedule 6
# detailed financial data.  It DOES NOT collect data for organisations without
# a completed Schedule 6.
# This function also handles the writing to file of the scraped finances.

def scrape_finance(webadd, finyear, orgid, orglink):

	trys = 0
	while trys<=3:
		try:
			rorg = requests.get(webadd)
			if rorg.status_code == 200:
				trys=5
			else:
				sleep(5)
		except:
			trys +=1
			sleep(5)
	#print(webadd, ' | ', rorg.status_code)

	# This dict will hold the scraped financial information
	sched6record = {}

	if rorg.status_code == 200:

		html_org = rorg.text
		soup_org = BeautifulSoup(html_org, 'html.parser')

		# Find the link to the Schedule 6 return if it exists
		schedule6 = soup_org.find(text="Schedule 6 - Detailed Financial Information")

		# Check if a valid link was found
		if schedule6 != None:
			if schedule6.parent.has_attr('href'):
				print(' | ** SCHEDULE 6')
				sched6_add = 'http://www.cra-arc.gc.ca' + schedule6.parent['href'].strip()
				# Use the Schedule 6 link to go and get the financial information, and return it into sched6record dict
				sched6record = scrape_sched6(sched6_add, finyear, orgid)
				# Add the relevant links to the dictionary for auditing
				sched6record['s6link']=sched6_add
				sched6record['yearlink']=webadd
				sched6record['orglink'] = orglink

			# If any of this fails, make an appropriate blank record to go into the output file	
			else:
				print(' | -- NO s6 link found')
				sched6record = {'orgid': orgid, 'year': finyear, 'sched6': 0, 'orglink': orglink, 'yearlink': webadd, }
		else:
			print(' | -- No schedule 6 returned')
			sched6record = {'orgid': orgid, 'year': finyear, 'sched6': 0, 'orglink': orglink, 'yearlink': webadd}

	else:
		sched6record = {'orgid': orgid, 'year': finyear, 'sched6': -1, 'orglink': orglink, 'yearlink': webadd}
		print(' | -- Link failed')

	# This is where we write the dict to the output file on each pass
	# The file has one row per financial year	
	writer.writerow(sched6record)


# This is the function doimg the dirty work of collecting the financial data from the 
# Schedule 6 page.  It takes advantage of the unique line numbers to code the data items.
# It just grabs any data item with a valid line number.

def scrape_sched6(webadd, finyear, orgid):

	trys = 0
	while trys<=3:
		try:
			rorg = requests.get(webadd)
			if rorg.status_code == 200:
				trys=5
			else:
				sleep(5)
		except:
			trys +=1
			sleep(5)
	#print(webadd, ' | ', rorg.status_code)


	if rorg.status_code == 200:

		sched6record = {'orgid': orgid, 'year': finyear, 'sched6': 0}

		html_org = rorg.text
		soup_org = BeautifulSoup(html_org, 'html.parser')

		# Find all the rows of the table, denoted by <tr> tags
		revenue_row = soup_org.find_all('tr')

		# If a row with data is found, then separate it into columns
		if revenue_row != []:
			# Record for the output file that we got this far - if this flag is set then we expect to see financial data
			sched6record['sched6'] = 1
			# Go through all the rows of the table in turn
			for row in revenue_row:
				# Columns are denoted by either <td> or <th> (The latter denotes totals in heading rows)
				col = row.find_all(['td', 'th'])
				if col != []:
					try:
						# The financial figures are in the third column. We strip out the dollar sign.
						figure = col[2].text.strip()
						# Rows with no financial data are recorded as n/a in the table, so ignore those
						if figure != 'n/a':
							figure = figure[2:]
						# Get the linenumber from the second column. This tells us what the number means, and is the key for the output dict	
						linenumber = col[1].text.strip()

						# Spacer rows in the table don't have valid 4-digit line numbers, so we can ignore them
						if len(linenumber) == 4:
							sched6record[linenumber] = figure
					except:
						# This picks up the parse above failing - at the moment we don't record that
						# It would appear in the output file as a row with the sched6 flag set to '1', but no data
						# so we can pick it up in the quality checks later.  We could always record something here if it's
						# a big problem.
						pass
	else:
		# If we don't manage to get a valid page at this stage just record in the output that no sched6 was found.
		# This could be extended to give other values of sched6 to help with debugging.
		sched6record = {'orgid': orgid, 'year': finyear, 'sched6': 0}

	# Return the dict containing the info that was scraped (or minimal info if scrape not successful)
	return sched6record
				

	
# ==========================================================


# ==========================================================
# MAIN PROGRAM
# ==========================================================


# Run the downloaddate function to get the date 'benefacts_master.py' was executed.
ddate = downloaddate()

# Set up the file paths
projectpath = './'
outputfilepath = projectpath + 'data_raw/' + ddate + '/canada_register_finance_sample_' + ddate + '.csv' 
inputfilepath = projectpath + 'data_raw/' + ddate + '/canada_register_sample_' + ddate + '.csv' 

# Set the file row tracking
startrow = 1
rowcounter=0


# Open the input file list of charities ...
with open(inputfilepath, 'r', newline='') as inCSVfile:

	# ... as a CSV file.
	reader = csv.reader(inCSVfile)

	# Open the output file for financial information ...
	with open(outputfilepath, 'w', newline='') as outCSVfile:

		# ... as a CSV dict.  Using dict here really simplifies storing the scrape data where many fields are missing
		outputfieldnames = ('orgid', 'year', 'sched6', 'orglink', 'yearlink', 's6link',  '5040', '4310', '4540', '4575', '4160', '4250', '4166', '4900', '4110', '4810', '4300', '4860', '5000', '4580', '4891', '4920', '4330', '4600', '4100', '4150', '4950', '4500', '4140', '4571', '4610', '4700', '4830', '4890', '4130', '4640', '4850', '5030', '4155', '5050', '4200', '4165', '4870', '5010', '4840', '4590', '4120', '4880', '4800', '4320', '4510', '5610', '4350', '4630', '4505', '4650', '4560', '5020', '4910', '5100', '4620', '4180', '4530', '4170', '4820', '4550', '4520', '5070', '5060', '5640', '4525')
		writer = csv.DictWriter(outCSVfile, fieldnames = outputfieldnames)
		writer.writeheader()

		# Ignore the first row of fieldnames in the input file
		while rowcounter<startrow:
			next(reader)
			rowcounter+=1

		# Iterate through the input file taking each charity in turn
		for row in reader:
			# We only really need the ID and NAME for each charity
			matchid = row[0]
			matchname = row[1]

			print('==============================')
			print('Organisation number:', rowcounter)
			print(matchid, matchname)

			# Build the organisation's web address
			orglink = buildwebadd(matchid, matchname)

			# Get the link to the t3010
			t3010link = getT3010(orglink)

			# If it exists, then scrape the financial data
			if t3010link != False:
				scrapeorg(t3010link, matchid)
				sleep(random.randint(2,4))
			else:
				# Otherwise write a record with missing data to show that we couldnt get any financial data for this organisation
				sched6record = {'orgid': matchid, 'year': -9, 'sched6': -9}
				writer.writerow(sched6record)
			# Keep count of the rows to help the user track progress
			rowcounter +=1
