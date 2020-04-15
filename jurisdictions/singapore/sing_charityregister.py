## Python script to download a monthly snapshot of the Singapore Charity Register from the Commissioner of Charities' Charity Portal

# Diarmuid McDonnell
# Created: 26 February 2018
# Last edited: captured in file history on Github repository


################################# Import packages #################################
from urllib.request import urlopen as uReq
from bs4 import BeautifulSoup as soup
from lxml.html import fromstring
from itertools import cycle
from datetime import datetime
from downloaddate_function import downloaddate
from time import sleep
from dropbox.files import WriteMode
from selenium import webdriver
import requests
import json
import base64
import dropbox
import pandas as pd
import csv
import os
import io
import numpy as np

# Run the downloaddate function to get today's date
ddate = downloaddate()

# Define paths where 
projpath = 'C:/Users/mcdonndz-local/Desktop/github/singapore_charity_data/'
datapath = 'C:/Users/mcdonndz-local/Desktop/github/singapore_charity_data/data/'

print(projpath)
print(datapath)

# Define url where the data can be downloaded
regurl = 'https://www.charities.gov.sg/_layouts/MCYSCPSearch/MCYSCPSearchCriteriaPage.aspx'
charurl = 'https://www.charities.gov.sg/_layouts/MCYSCPSearch/MCYSCPSearchOrgProfile.aspx?AccountId=MGEzMzllMmQtNzk2NS1lMzExLTgyZGItMDA1MDU2YjMwNDg0'

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
'''
rorg = requests.get(regurl, headers=headers) # 
print(rorg.status_code)
if rorg.status_code==200:
	html_org = rorg.text # Get the text elements of the page.
	soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.
	print(soup_org) # The request works but the trick is click the search button without launching a browser.
'''
# Example of an account id and UEN
uen = '201105101N'
accid = 'MzA2MTFiNzItMjBkNC1lMzExLWFkYjUtMDA1MDU2YTQxZjJk'
print(len(uen))	
print(len(accid))

code = base64.b64decode(accid)
print(code)

'''
# Tell browser to download data to the correct folder
chrome_options = webdriver.ChromeOptions()
prefs = {'download.default_directory' : datapath}
chrome_options.add_experimental_option('prefs', prefs)

# We need to download separate registers for each type of charity: Registered Charities/IPCs/Fund-raising Permits/Exempt charities/De-registered
chartype = {'regchar': 'ctl00_PlaceHolderMain_rblSearchCategory_0', 'ipc': 'ctl00_PlaceHolderMain_rblSearchCategory_1', 
'exempt': 'ctl00_PlaceHolderMain_rblSearchCategory_2', 'fundraising': 'ctl00_PlaceHolderMain_rblSearchCategory_3', 
'deregchar': 'ctl00_PlaceHolderMain_rblSearchCategory_4'}

# Specify options in drop-down menus e.g. income range, activities, sector
incomeid = 'ctl00_PlaceHolderMain_ddlIncomeRange'
income = {'0': '1', '<50k': '2', '50-200k': '3', '200-250k': '4', '250-500k': '5', '500k-1m': '6', '1-5m': '7', '5-10m': '8', '>10m': '9'}

sectorid = 'ctl00_PlaceHolderMain_ddlCharitySector'
sector = {'Arts and Heritage': '9e73b6ff-86a2-e211-b716-005056b30ba7', 'Community': '7a479520-87a2-e211-b716-005056b30ba7', 
'Education': '4a0860ef-86a2-e211-b716-005056b30ba7', 'Health': 'b2723ee6-86a2-e211-b716-005056b30ba7', 
'Religious': '1ed69f16-87a2-e211-b716-005056b30ba7', 'Social and Welfare': 'a2bdf80e-87a2-e211-b716-005056b30ba7', 
'Sports': '062fad64-87a2-e211-b716-005056b30ba7', 'Others': '1e89064e-aba1-e211-9d84-005056a402dc'}

# Define an object to count the number of files downloaded
filecounter = 0

# Download search results for each element in the chartype list
for key, val in chartype.items():
	# Launch a browser and point it at the Data Portal url
	browser = webdriver.Chrome(chrome_options=chrome_options)
	browser.get(url)
	browser.maximize_window()
	try:
		# Select correct radio button
		radiobutton = browser.find_element_by_id(val)
		browser.execute_script("$(arguments[0]).click();", radiobutton)

		# Loop through financial size search options
		#for inckey, incval in income.items():
		#	select = Select(driver.find_element_by_id(incomeid))
		#	select.select_by_value(incval)
			
		# Click the search button
		search = browser.find_element_by_id('ctl00_PlaceHolderMain_btnSearch')
		browser.execute_script("$(arguments[0]).click();", search)
	
		# Click the download button
		download = browser.find_element_by_id('ctl00_PlaceHolderMain_btnDownloadCSV')
		browser.execute_script("$(arguments[0]).click();", download)

		print('Successfully downloaded ' + key + ' file')
		#print('Successfully downloaded ' + key + '_' + inckey + 'file')
		filecounter+1
		# Rename the file
		for f in os.listdir(datapath):
			os.rename(os.path.join(datapath, f), os.path.join(datapath, key + '_' + inckey + '.xlsx'))
		sleep(30) # Pause the script to allow the file to download	
		browser.quit() # Close the browser
	except:
		print('Was not able to find ' + key + ' file')	
		sleep(30)
		browser.quit() # Close the browser
		#print('Was not able to find ' + key + '_' + inckey + 'file')	

print('Script finished running - downloaded ' + str(filecounter) + ' files')
'''