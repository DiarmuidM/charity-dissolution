## Python script to get links to quick and full view for each charity and test for the presence of hidden links from older periods.

# Tom Wallace
# Created: 07 June 2019
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
sleeptime = 5 # This is how long to sleep between each page grab - 5 seconds makes the scraper take about 5.5 hours in total.
clean_start = False
probe_depth = 4 # How many links to test for each charity (will test twice this number as it is called for quick links and full links), is affected by stop_when_fail
stop_when_fail = True # If true this will stop the probing for each charity as soon as a page returns False for valid

#######Initialization#######
log_starttime = longtime() # Get the start time for the log file

projpath = './'
datapath = projpath + 'data_raw/'
input_path = datapath + 'Register_scrape/'
output_path = datapath + 'Infreturn/'

if not os.path.exists(output_path): # If the path doesn't exist, make it
	os.makedirs(output_path)

#######Functions######
def link_tester(link):
	#This tries to get a link and returns True if genuine info comes back, False if an error page comes back and None if no page comes back.
	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
	try:
		page = requests.get(link, headers=headers)
	except:
		valid = None
		return valid
	html = page.text # Get the text elements of the page.
	soup_page = soup(html, 'html.parser') # Parse the text as a BS object.
	valid = None
	
	#Quick view true
	try:
		test_content = soup_page.find("div", class_="col-xs-12 col-sm-6 col-md-6 col-lg-9")
		test_content = test_content.text.strip()
		print(test_content) #####################i was here
		if 'RR' in test_content:
			valid = True
	except:
		pass
	
	#Full view true
	try:
		test_content = soup_page.find("h1", id="wb-cont", class_="mrgn-tp-sm mrgn-bttm-sm")
		test_content = test_content.text.strip()
		if 'Registered charity information return' in test_content:
			valid = True
	except:
		pass
	
	#Quick view false
	try:
		test_content = soup_page.find("section", class_="col-md-6")
		test_content = test_content.text.strip()
		if 'Internal server error' in test_content:
			valid = False
	except:
		pass
	
	#Full view false
	try:
		test_content = soup_page.find("h1", id="wb-cont")
		test_content = test_content.text.strip()
		if 'Error—' in test_content:
			valid = False
	except:
		pass

	return valid

def linker(soup_page,link,type_link):
	link_list = soup_page.find_all("ul", class_="list-unstyled mrgn-lft-md")
	
	#Quick links
	if type_link == 'Quick':
		link_list_func = link_list[0]
	if type_link == 'Full':
		link_list_func = link_list[1]

	period_list = link_list_func.text.split('\n')
	period_list = [item for item in period_list if item !='']

	link_list_func = link_list_func.find_all(href=True)

	link_list_func = list(map(lambda x : x.get('href'), link_list_func))
	link_list_func = list(map(lambda x : 'https://apps.cra-arc.gc.ca' + x, link_list_func))
	if type_link == 'Quick':
		link_list_func.insert(0,link)

	valid_list = [True for link in link_list_func]
	if type_link == 'Quick':
		type_list = ['Quick links' for link in link_list_func]
		type_list[0] = 'Base URL'
	if type_link == 'Full':
		type_list = ['Full links' for link in link_list_func]
	period_num=[]
	for link in link_list_func:
		try: 
			number =  re.search('(?<=PeriodIndex=)\d+', link).group(0)
		except:
			number = 0
		period_num.append(number)

	try:
		maxnum_list = re.findall('(?<=selectedFilingPeriodIndex=)\d+(?=&)', str(link_list_func))
		maxnum_list = list(map(lambda x : int(x), maxnum_list))
		maxnum = max(maxnum_list)
	except:
		maxnum = 0
	
	charid = re.search('(?<=selectedCharityId=)\d+',link).group(0)
	charno = re.search('(?<=Bn=)\d{9}RR\d{1,4}(?=&)',link).group(0)

	for num in range(maxnum+1,maxnum+probe_depth+1):
		test_link ='https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyQckVw?q.stts=0007&selectedFilingPeriodIndex=' + str(num) + '&selectedCharityId=' + str(charid) + '&selectedCharityBn=' + charno + '&isSingleResult=false'
		valid = link_tester(test_link)
		#print('Probe result:', valid)
		link_list_func.append(test_link)
		period_list.append('NA')
		valid_list.append(valid)
		if type_link == 'Quick':
			type_list.append('Quick links')
		if type_link == 'Full':
			type_list.append('Full links')
		period_num.append(num)
		if valid==False and stop_when_fail==True: # This will stop the script probing as soon as it fails to find a page, this stops it making extra requests if we suspect the hidden pages to be sequential
			break # I.e. leave this option on unless we suspect odd paterns of hidden pages like 4-exists 5-notexists 6-exists - i don't syspect this.

	charityno_list = [charno for each in link_list_func]
	scrapetime_list = [scrapetime for each in link_list_func]
	export_data = zip(charityno_list, link_list_func, type_list, period_num, period_list, valid_list, scrapetime_list)
	with open(output_file, 'a', encoding='1252', errors='replace', newline='') as resultsfile:
		wr = csv.writer(resultsfile)
		wr.writerows(export_data)
	resultsfile.close()

def isNowInTimePeriod(startTime, endTime):
	downtime = longtime()
	nowTime = str(downtime.time().hour) + ':' + str(downtime.time().minute) 

	if startTime < endTime:
		return nowTime >= startTime and nowTime <= endTime
	else: #Over midnight
		return nowTime >= startTime or nowTime <= endTime

#######Main program######
#Input file - read in char links
input_file = input_path + 'ca_char_list.csv'

with open(input_file, 'r', encoding='1252', errors='replace', newline='') as inputfile: # At the end, this reads the output file back in and checks it contains the same number of records as the target
	df = pd.read_csv(inputfile)
inputfile.close()
charlinks_list = df['Link'].tolist() 
#print(sys.getsizeof(charlinks_list)) # This is a large list but still uner 1mb in memory

#Output file
output_file = output_path + 'ca_char_infreturn.csv'
if clean_start==True or os.path.isfile(output_file)==False: # This only overwrites the file with new headers if a toggle is set or the file dosen't exsit- otherise the script will pick up where it left off and append
	with open(output_file, 'w', encoding='1252', errors='replace', newline='') as resultsfile:
		wr = csv.writer(resultsfile)
		wr.writerow(('Char_no', 'Link', 'Type', 'Period number', 'Period label', 'Exists?', 'Scrape time'))
	resultsfile.close()

#Remove charities from the list which have already been scraped
with open(output_file, 'r', encoding='1252', errors='replace', newline='') as checkoutput: # Read the existing results file in to check what's been done
	df = pd.read_csv(checkoutput)
checkoutput.close()

already_done_links = df['Link'].tolist() # already scraped links into a list
already_done_orgs = df['Char_no'].tolist() # already scraped links into a list

if os.path.isfile(output_path + 'Errors.txt')==True: # If the error file exists add its links to those to be skipped over
	with open(output_path + 'Errors.txt', 'r') as error_file: # This opens the error file so the scraper can pass over those links
		error_links = error_file.read().split('\n')
	error_file.close
	already_done_links = already_done_links + error_links # combine the sucsessfully done links with the error links - so both of these are skipped

charlinks_list = [link for link in charlinks_list if link not in already_done_links] # reconstruct the main list to exclude any which are already done

print('Skipping',len(set(already_done_orgs)), 'charities already in output file.\n')

link_counter = 1
#Main loop
for link in charlinks_list:
	scrapetime = longtime()
		
	timeStart = '6:50'
	timeEnd = '11:01'

	timeinrange = isNowInTimePeriod(timeStart, timeEnd)	
	while timeinrange == True:
		print('Regulator site down betweem 2am and 6am EST (7am and 11am BST), sleeping for 7 hours at:',scrapetime.time())
		sleep(7*60*60)
		timeinrange = isNowInTimePeriod(timeStart, timeEnd)	
	
	print('Getting links for charity: ',link, ' ', link_counter,'/',len(charlinks_list), ' at: ',scrapetime, sep='')

	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
	
	try:
		page = requests.get(link, headers=headers) # This is an initial grab of the page
	except:
		page = requests.get('https://www.webscraper.io/test-sites/e-commerce/allinone', headers=headers) # if it fails to return anything then grab a random working page just so there is a requests object to test with the while loop below
	errorcount=0
	multi_bad_page_error=False
	while 'Registration no.:' not in page.text: # If certain text isn't found in the page then it's either an error page or possibly the random page from above - so go into a while loop and try until the page is correct. This should catch bad requests and error pages (which are good requests but the wrong pages)
	#while page==0: # This block of code makes the scraper robust to disconnection - it will keep trying and sleeping forever so keep an eye on it.
		try:
			errorcount = errorcount+1
			print('Bad page, sleeping for 5 seconds.')
			sleep(5)
			page = requests.get(link, headers=headers)
			if errorcount >=3:
				print('Multiple bad pages, skipping this charity and writing link to error file.')
				errorcount=0
				multi_bad_page_error = True
				break
		except:
			print('Disconnected, sleeping for 5 seconds')
			sleep(5)
			errorcount = errorcount + 1
			if errorcount==5:
				print('Multiple disconnections, sleeping for 100 mins at:', scrapetime)
				sleep(100*60)
				errorcount=0
			else:
				pass

	if multi_bad_page_error==True:
		with open(output_path + 'Errors.txt', 'a') as error_file:
			error_file.write(link+'\n')
		error_file.close
		continue
	html = page.text # Get the text elements of the page.
	soup_page = soup(html, 'html.parser') # Parse the text as a BS object.

	type_list='Quick' 
	linker(soup_page,link,type_list)
	type_list='Full' 
	linker(soup_page,link,type_list)	
	
	link_counter = link_counter+1
	sleep(sleeptime)

# add what period the link refers to?

#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'This script gets the quick and full links listed on each charities page and then tests for hidden links beyond those.'
processedfiles = input_file # Get the input file details
writtenfiles = [output_file,output_path + 'Errors.txt'] # Get list of created files
settings_toggles = {'sleeptime':sleeptime, 'clean_start':clean_start, 'probe_depth':probe_depth,'stop_when_fail':stop_when_fail}
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generator

print('All done!')