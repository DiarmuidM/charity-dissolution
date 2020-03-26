## Python script to download direct links and charnumbers for all Canadian charities. This downloads a page at a time each with 100 charities and grabs the links to their detailed records for a future script to scrape.

# Tom Wallace
# Created: 06 June 2019
# Last edited: captured in Github file history

#######Import packages######
from urllib.request import urlopen as uReq
from bs4 import BeautifulSoup as soup
import requests
import time
from time import sleep
import re
import pandas as pd
import sys
import os
import csv
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import longtime, downloaddate
from loggenerator import gen_log

#######Toggles#######
start_fresh = False # This, if set False, allows the scraper to pick up where it left off if it failed during a run. If set true it will overwrite any previous results and start from page 1.
sleeptime = 5 # This is how long to sleep between each page grab - 5 seconds makes the scraper take about 5.5 hours in total.

#######Initialization#######
log_starttime = longtime() # Get the start time for the log file

projpath = './'
datapath = projpath + 'data_raw/Register_scrape/'

if not os.path.exists(datapath): # If the path doesn't exist, make it
	os.makedirs(datapath)

baseurl = 'https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/advncdSrch?dsrdPg=' # This is the URL for the search of all charities - it just need a page number between the base and suffix
suffixurl = '&q.stts=0007&q.ordrClmn=NAME&q.ordrRnk=ASC'
#######Main program######


#Output file
output = datapath + 'ca_char_list.csv'

if not os.path.exists(output): # This will check if the output file exists - if it doesn't then the program must fresh start and the toggle above will be overridden.
	print('Output file not found, fresh starting...\n')
	start_fresh = True

if start_fresh == True: # If this starts fresh by writing the output file with its headers.
	with open(output, 'w', encoding='1252', errors='replace', newline='') as resultsfile:
		wr = csv.writer(resultsfile)
		wr.writerow(('Char_no', 'Char_ID', 'Name', 'Link', 'Effective_date', 'Page_no_program', 'Page_no_base_url', 'Page_no_char_url', 'Page_no_match', 'Timestamp', 'Source_page_url'))
		start_page = 1
		max_pg = 0
	resultsfile.close()
else:
	with open(output, 'r', encoding='1252', errors='replace', newline='') as resultsfile: # This is a 'hot' start and will read in the existing output file to work out where it needs to start to pick up where the file left off
		df = pd.read_csv(resultsfile)
		max_pg = df['Page_no_program'].max() # Find the maximum page the file got up to and start from that +1 - this will not fix pages which failed to scrape properly.
		start_page = max_pg + 1
	resultsfile.close()

#Page range
# This block scrapes the first page and works out how many records there are and so how many pages there must be to get.
calc_url = 'https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/advncdSrch?dsrdPg=1&q.stts=0007&q.ordrClmn=NAME&q.ordrRnk=ASC'
calc = requests.get(calc_url)
html_calc = calc.text # Get the text elements of the page.

set_size = re.search('(?<=of )\d+(?= entries on this page)', html_calc).group(0)
page_requ = int(int(set_size)/100) + 1
print(page_requ-max_pg,'out of',page_requ, 'pages to scrape...\n')

#Main loop
for page in range(start_page,page_requ+1,1): # Start page is determined by the fresh start settings, page_requ is determined in page range above, must be +1 because of Python's odd range rules
	scrapetime = longtime()
	print('Getting page',page)
	scrapeurl = baseurl + str(page) + suffixurl

	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.

	rorg = 0
	errorcount=0

	while rorg==0: # This block of code makes the scraper robust to disconnection - it will keep trying and sleeping forever so keep an eye on it.
		try:
			rorg = requests.get(scrapeurl, headers=headers)
		except:
			print('Disconnected, sleeping for 5 seconds')
			sleep(5)
			errorcount = errorcount + 1
			if errorcount==3:
				print('Multiple disconnections, sleeping for 100 mins')
				sleep(100*60)
				errorcount=0
			else:
				pass
	try:
		html = rorg.text # Get the text elements of the page.
		soup_page = soup(html, 'html.parser') # Parse the text as a BS object.

		orgs = soup_page.find_all("td", class_="text-center", headers="headername") 

		names = list(map(lambda x : x.text, orgs))
		names = list(map(lambda x : x.strip(), names)) # Gte the names and format them

		links = list(map(lambda x : x.find(href=True), orgs))
		links = list(map(lambda x : x.get('href'), links)) # Find and then grab URLs
		charity_page_stem = 'https://apps.cra-arc.gc.ca'
		links = list(map(lambda x : charity_page_stem + x, links)) # Stick the stem on each link so it's a fully functioning URL

		dates = soup_page.find_all("td", class_="text-center", headers="header5", style="white-space: nowrap;") # Date charity was registered

		dates = list(map(lambda x : x.text, dates))
		dates = list(map(lambda x : x.strip(), dates))

		charnos = list(map(lambda x : re.search('(?<=Bn=)\d{9}RR\d{1,4}(?=&)', x).group(0), links)) # Get that charity number and ID by disecting each charity's link
		charIDs = list(map(lambda x : re.search('(?<=CharityId=)\d+(?=&)', x).group(0), links))

		page_list = [str(page) for each in names] # This just creates a list the same length as 'names' which contains the current page number. It's a quick way of making a list for a constant.
		#The above is a short way of saying: 'For each element in the list names, add the page number to a list called page_list'

		url_page_no = list(map(lambda x : re.search('(?<=Pg=)\d+$', x).group(0), links)) # This grabs the page number from each charity URL so it can be checked against the internal number

		base_page_no = re.search('(?<=Pg=)\d+(?=&)', scrapeurl).group(0) # This grabs the page number from the base URL (the page which is being scraped)
		base_page_no_list = [base_page_no for each in names]

		valid = [page_list==url_page_no==base_page_no_list for each in links] # This checks if the internal page number running the loop, the base page number and the charity URL page number all match and creates a bool list. They should always match.

		scrapetime_list = [scrapetime for each in names] # Same as above, this creates a list of identical scrape times
		scrapeurl_list = [scrapeurl for each in names] # Create list of the base URL

		export_data = zip(charnos, charIDs, names, links, dates, page_list, base_page_no_list, url_page_no, valid, scrapetime_list, scrapeurl_list) # Zip all the output lists up for writing
	except:
		export_data = [['>>> WARN: Scrape of page ' + str(page) + ' failed <<<', scrapeurl]] # If a page scrape fails write an error to the output file
		print(export_data)
	
	#Writer
	with open(output, 'a', encoding='1252', errors='replace', newline='') as resultsfile:
		wr = csv.writer(resultsfile)
		wr.writerows(export_data)
	resultsfile.close()

	print('Timestamp:',scrapetime)
	print('Page', page, 'scraped,', "{0:.2f}".format((page/(page_requ))*100), '% done, sleeping for', sleeptime,'seconds.\n')
	sleep(sleeptime)

#Validation
with open(output, 'r', encoding='1252', errors='replace', newline='') as resultsfile: # At the end, this reads the output file back in and checks it contains the same number of records as the target
	df = pd.read_csv(resultsfile)
	if len(df) == set_size:
		print('\nResults validated')
	else:
		print('>>> WARN: There were', set_size, 'charities to scrape but the results file contains', len(df), '<<<')
		print('Please check the results file for errors or rerun the script.')
		quit() # if the results are invalid then quit before writing the log file
resultsfile.close()

#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'This script downloads pages of results from the Canadian charity advanced search to collect links for each charities individual records.'
processedfiles = calc_url # Get the input file details
writtenfiles = output # Get list of created files
settings_toggles = {'start_fresh':start_fresh, 'sleeptime':sleeptime}
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generator

print('All done!')
