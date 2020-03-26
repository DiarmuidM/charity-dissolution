## Python script to download a monthly snapshot of the Scottish Charity Register

# Diarmuid McDonnell
# Created: 28 March 2018
# Last edited: captured in Github file history

'''
	Checkbox:
	<input id="ContentPlaceHolderDefault_WebsiteContent_ctl05_CharityRegDownload_10_cbTermsConditions" type="checkbox" name="ctl00$ctl00$ctl00$ContentPlaceHolderDefault$WebsiteContent$ctl05$CharityRegDownload_10$cbTermsConditions">

	Proceed button:
	 <input type="submit" name="ctl00$ctl00$ctl00$ContentPlaceHolderDefault$WebsiteContent$ctl05$CharityRegDownload_10$btnProceed" 
	 value="Proceed" onclick="javascript:WebForm_DoPostBackWithOptions(new WebForm_PostBackOptions(&quot;ctl00$ctl00$ctl00$ContentPlaceHolderDefault$WebsiteContent$ctl05$CharityRegDownload_10$btnProceed&quot;, 
	 &quot;&quot;, true, &quot;&quot;, &quot;&quot;, false, false))" id="btnProceed">
'''

import itertools
import json
import csv
import re
import requests
import os
import os.path
import errno
import urllib
from time import sleep
from bs4 import BeautifulSoup
from selenium import webdriver
import mechanicalsoup
from downloaddate_function import downloaddate

# Note that 'pip install selenium' and 'pip install MechanicalSoup' needs to be run from the command line to install the module (one time).
# Also, chromedriver.exe needs to be downloaded and placed somewhere for it to work - https://sites.google.com/a/chromium.org/chromedriver/downloads


# Run the downloaddate function to get the date 'benefacts_master.py' was executed.
ddate = downloaddate()

projpath = 'C:/Users/mcdonndz-local/Desktop/github/scotland_charity_data/'
datapath = 'C:/Users/mcdonndz-local/Desktop/data/scotland_charity_data/data_raw/'

print(projpath)
print(datapath)

# Create a folder for the download to be saved in #
try:
	os.mkdir(datapath+ddate)
except:
	print('Folder already exists')


url = 'https://www.oscr.org.uk/about-charities/search-the-register/charity-register-download'

# See if selenium webdriver can find and click the correct object #

options = webdriver.ChromeOptions() 
options.add_argument("download.default_directory=C:/Users/mcdonndz-local/Desktop/data/scotland_charity_data/data_raw/")
#https://stackoverflow.com/questions/35331854/downloading-a-file-at-a-specified-location-through-python-and-selenium-using-chr

# Launch the browser and point it to the Scottish Charity Register url
browser = webdriver.Chrome(chrome_options=options)
browser.maximize_window()
browser.get(url)

# Find the checkbox and proceed button, and click them
try:
	elem = browser.find_element_by_id("ContentPlaceHolderDefault_WebsiteContent_ctl05_CharityRegDownload_10_cbTermsConditions")
	print("Checkbox is not selected..now selecting it")
	browser.execute_script('$(arguments[0]).click();', elem)

	proceed = browser.find_element_by_id('btnProceed')
	browser.execute_script("$(arguments[0]).click();", proceed)

	#browser.close()

except Exception as e:
	print('Was not able to find an element with that name', format(e))

finally:
	#browser.quit()	
	print('Finished executing Python script')
# Great, this all works. The remaining issues:
#			- How do we download to the correct folder? Currently downloads to 'Downloads folder'
#			- Can this script be automated on AWS or Raspberry Pi?