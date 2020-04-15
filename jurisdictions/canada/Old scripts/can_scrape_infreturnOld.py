## Python script 

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
	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
	page = requests.get(link, headers=headers)
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

#######Main program######
#Input file - read in char links
input_file = input_path + 'ca_char_list.csv'

with open(input_file, 'r', encoding='1252', errors='replace', newline='') as inputfile: # At the end, this reads the output file back in and checks it contains the same number of records as the target
	df = pd.read_csv(inputfile)
inputfile.close()
charno_list = df['Char_no'].tolist() # This is a large list but still uner 1mb in memory
charid_list = df['Char_ID'].tolist() 

#Output file
output_file = output_path + 'ca_char_infreturn.csv'
with open(output_file, 'w', encoding='1252', errors='replace', newline='') as resultsfile:
	wr = csv.writer(resultsfile)
	wr.writerow(('Char_no', 'Link', 'Type', 'Period number', 'Exists?', 'Scrape time'))
resultsfile.close()

#Main loop
for charno, charid in zip(charno_list,charid_list): # 
	scrapetime = longtime()
	print('Getting links for charity: ',charno)
	
	#Quick links
	valid = None
	link_list,valid_list,type_list,period_num=[],[],[],[]

	for number in range(0,100,1):
		quick_link ='https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyQckVw?q.stts=0007&selectedFilingPeriodIndex=' + str(number) + '&selectedCharityId=' + str(charid) + '&selectedCharityBn=' + charno + '&isSingleResult=false'
		valid = link_tester(quick_link)
		print('return quick:', valid)
		link_list.append(quick_link)
		valid_list.append(valid)
		type_list.append('Quick links')
		period_num.append(number)
		if valid == False:
			break

	#Full links
	for number in range(0,100,1):
		full_link = 'https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyT3010FrFlngPrd?q.stts=0007&selectedFilingPeriodIndex=' + str(number) + '&selectedCharityId=' + str(charid) + '&selectedCharityBn=' + charno + '&isSingleResult=false'
		valid = link_tester(full_link)
		print('return full:', valid)
		link_list.append(full_link)
		valid_list.append(valid)
		type_list.append('Full links')
		period_num.append(number)
		if valid == False:
			break

	charityno_list = [charno for each in link_list]
	scrapetime_list = [scrapetime for each in link_list]
	export_data = zip(charityno_list, link_list, type_list, period_num, valid_list, scrapetime_list)
	with open(output_file, 'a', encoding='1252', errors='replace', newline='') as resultsfile:
		wr = csv.writer(resultsfile)
		wr.writerows(export_data)
	resultsfile.close()


"""
#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'This script downloads pages of results from the Canadian charity advanced search to collect links for each charities individual records.'
processedfiles = calc_url # Get the input file details
writtenfiles = output # Get list of created files
settings_toggles = {'start_fresh':start_fresh, 'sleeptime':sleeptime}
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generator
"""
print('All done!')
