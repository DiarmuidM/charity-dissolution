# Scrape Trustee details for Australian charities - server test
# Diarmuid McDonnell
# 13/11/18
# This file scrapes trustee information from the ACNC website.
# 
#
# Do not forget to create a requirements.txt file for the Australia scripts
#

################################# Import packages #################################

from bs4 import BeautifulSoup as soup
from datetime import datetime as dt
import requests
import re


# Get the current date
ddate = dt.now().date()
print(ddate)

webadd = 'https://www.acnc.gov.au/charity/2d1cadda28335431f48afc9aea430a33?page=0' # Web address of charity's details
# headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
			
rorg = requests.get(webadd) # Grab the page using the URL and headers.
print('Status code: ', rorg.status_code) # Successfully requested
print(rorg.headers)

print('\r')
print('-------------------')
print('\r')

html_org = rorg.text # Get the text elements of the page.
soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.
print(soup_org)

print('\r')
print('-------------------')
print('\r')

tsection = soup_org.find('h3', text = re.compile('Responsible'))
print(tsection)

print('\r')
print('-------------------')
print('\r')

trustag = soup_org.find_all('div', {'class': ' col-xs-12 col-sm-6 col-md-4 col-lg-3 person'})
print(trustag)
for el in trustag:
	print(el)
'''
if soup_org.find('div', class_='group-info field-group-div'):
	print(grouptag)
# If there are trustee details on the webpage:
elif soup_org.find('div', {'class': ' col-xs-12 col-sm-6 col-md-4 col-lg-3 person'}):
	print('Found trustee details')
	trusteedetails = soup_org.find('div', {'class': ' col-xs-12 col-sm-6 col-md-4 col-lg-3 person'})
	print(trusteedetails)
else:
	print('Could not find trustee details e.g. charity status is revoked or group charity')
'''	