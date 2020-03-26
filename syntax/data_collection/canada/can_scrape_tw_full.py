## Python script 

# Tom Wallace
# Created: 22 August 2019
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
import pickle
from random import shuffle
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import longtime, downloaddate
from loggenerator import gen_log

pd.set_option('display.max_columns', 500)

#######Initialization#######
log_starttime = longtime() # Get the start time for the log file

projpath = './'
datapath = projpath + 'data_raw/'
input_path = datapath + 'Register_scrape/'
output_path = datapath + 'Scrape/'

if not os.path.exists(output_path): # If the path doesn't exist, make it
	os.makedirs(output_path)

#######Main program######
#Input file - read in char links
input_file = input_path + 'ca_char_list.csv'

with open(input_file, 'r', encoding='1252', errors='replace', newline='') as inputfile: # At the end, this reads the output file back in and checks it contains the same number of records as the target
	df = pd.read_csv(inputfile)
inputfile.close()
BN_no = df['Char_no'].tolist()
char_ID = df['Char_ID'].tolist() 

print(len(BN_no))
print(len(char_ID))


#Output file
output_file = output_path + 'ca_char_scrape.csv'
with open(output_file, 'w', encoding='1252', errors='replace', newline='') as resultsfile:
	wr = csv.writer(resultsfile)
	wr.writerow(('Char_no', 'Expenditure', 'Finanace link', 'Source page link', 'Name', 'Program area 1', 'Program area 2', 'Program area 3', 'Revneue', 'Trustee link', 'Wrapped','Year', 'Active', 'Foundation','Subordinate'))
resultsfile.close()

#Link constructor
charlinks_list=[]
for bn,ID in zip(BN_no,char_ID):
	for num in range(0,6):
		link='https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyT3010FrFlngPrd?q.stts=0007&selectedFilingPeriodIndex='+str(num)+'&selectedCharityId='+str(ID)+'&selectedCharityBn='+str(bn)+'&isSingleResult=false'
		charlinks_list.append(link)

fixed_links=[]
for link in charlinks_list:
	link = re.split("(?<=\d)RR(?=\d+&)", link)
	link = link[0]+'RR000'+link[1]
	fixed_links.append(link)

print(len(fixed_links))

shuffle(fixed_links)

#fixed_links = ['https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyT3010FrFlngPrd?q.stts=0007&selectedFilingPeriodIndex=0&selectedCharityId=124410510&selectedCharityBn=118793074RR00049&isSingleResult=false']

for link in fixed_links:
	print('\n', link)
	charno = re.search('(?<=CharityId=)\d+',link).group(0)
	bnno = re.search('(?<=CharityBn=)\d+RR\d+',link).group(0)
	try:
		page = requests.get(link)
		pickle.dump(page, open( './page', 'wb'))
		page = pickle.load(open( './page', 'rb'))

		page_text = page.text
		page_soup = soup(page_text, 'html.parser')
		header = page_soup.find('h2', class_='mrgn-tp-sm mrgn-bttm-lg').text.strip()
		year = re.search('^\d+', header).group(0)
		print(year)
		name = re.search('(?<=Registered charity information return for ).+', header).group(0)
		print(name)
		wrapped = page_soup.find('div', text=re.compile('Has the charity wound-up, dissolved, or terminated operations?')) #
		wrapped = wrapped.next_sibling.next_sibling.text.strip()
		
		subordinate = page_soup.find('div', text=re.compile('Was the charity in a subordinate position to a head body?')) #
		subordinate = subordinate.next_sibling.next_sibling.text.strip()

		foundation = page_soup.find('div', text=re.compile('Is the charity designated as a public foundation or private foundation?')) #
		foundation = foundation.next_sibling.next_sibling.text.strip()

		active = page_soup.find('div', text=re.compile('Was the charity active during the fiscal period?')) #
		active = active.next_sibling.next_sibling.text.strip()
		
		turstee_link = page_soup.find('a', text=re.compile('Directors/Trustees and Like Officials Worksheet.'))
		turstee_link = 'http://www.cra-arc.gc.ca' + turstee_link['href'].strip()
		
		prog_areas1 = page_soup.find('td', text=re.compile('^1$'))
		prog_areas1 = prog_areas1.parent
		prog_areas1 = prog_areas1.find_all('td')
		prog_areas1 = [part.text for part in prog_areas1]
		prog_areas1 = list(map(lambda x :x.strip(), prog_areas1))

		prog_areas2 = page_soup.find('td', text=re.compile('^2$'))
		prog_areas2 = prog_areas2.parent
		prog_areas2 = prog_areas2.find_all('td')
		prog_areas2 = [part.text for part in prog_areas2]
		prog_areas2 = list(map(lambda x :x.strip(), prog_areas2))

		prog_areas3 = page_soup.find('td', text=re.compile('^3$'))
		prog_areas3 = prog_areas3.parent
		prog_areas3 = prog_areas3.find_all('td')
		prog_areas3 = [part.text for part in prog_areas3]
		prog_areas3 = list(map(lambda x :x.strip(), prog_areas3))
		#print(prog_areas3)
		
		financelink = page_soup.find('a', text=re.compile('Schedule 6 - Detailed financial information'))
		if financelink!=None:
			financelink = 'http://www.cra-arc.gc.ca' + financelink['href'].strip()
		else: 
			financelink = 'NA'

		if financelink == 'NA':
			tot_revenue = page_soup.find(text=re.compile('4700'))
			tot_revenue = tot_revenue.parent.parent.parent
			tot_revenue = tot_revenue.find_all('div')
			tot_revenue = tot_revenue[2].text.strip()

			tot_expend = page_soup.find(text=re.compile('5100'))
			tot_expend = tot_expend.parent.parent.parent
			tot_expend = tot_expend.find_all('div')
			tot_expend = tot_expend[2].text.strip()
		else:
			tot_revenue = 'NA'
			tot_expend = 'NA'
	except:
		name = 'Null'
		wrapped = 'Null'
		year = 'Null'
		subordinate = 'Null'
		foundation = 'Null'
		active = 'Null'
		turstee_link = 'Null'
		prog_areas1 = 'Null'
		prog_areas2 = 'Null'
		prog_areas3 = 'Null'
		financelink = 'Null'
		tot_revenue = 'Null'
		tot_expend = 'Null'

	"""
	headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
	fin_page = requests.get('http://www.cra-arc.gc.ca/ebci/hacc/srch/pub/t3010/v23/t3010Schdl6_dsplyovrvw', headers=headers, allow_redirects=True)
	#pickle.dump(fin_page, open( './fin_page', 'wb'))
	#fin_page = pickle.load(open( './fin_page', 'rb'))

	fin_page_text = fin_page.text
	fin_page_soup = soup(fin_page_text, 'html.parser')
	print(fin_page_soup)
	

	assets_tot = fin_page_soup.find('kbd', text=re.compile('4200')) #
	print(assets_tot)
	assets_tot = assets_tot.next_sibling.next_sibling.text.strip()

	revenue_tot = fin_page_soup.find('kbd', text=re.compile('4700')) #
	#print(revenue_tot)
	revenue_tot = revenue_tot.next_sibling.next_sibling.text.strip()

	expenditure_tot = fin_page_soup.find('kbd', text=re.compile('5100')) #
	#print(expenditure_tot)
	expenditure_tot = expenditure_tot.next_sibling.next_sibling.text.strip()
	
	"""

	dicto = {'Charno':charno, 'Link':link, 'Name': name,'Wrapped':wrapped, 'Year':year, 'subordinate':subordinate, 'foundation':foundation, 'active':active,'Trustee link':turstee_link, 'Program area 1':str(prog_areas1), 'Program area 2':str(prog_areas2),'Program area 3':str(prog_areas3), 'Finance link':financelink, 'Revenue':tot_revenue, 'Expenditure':tot_expend} # Store the new variables as a dictionary
	df_csv = pd.DataFrame(dicto, index=[0])
	df_csv.set_index('Charno', inplace=True)
	with open(output_file, 'a', newline='') as f:
		df_csv.to_csv(f, header=False, encoding='cp1252')
