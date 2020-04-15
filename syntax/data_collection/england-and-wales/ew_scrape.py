#Scrape Trustee details
#Tom Wallace, Diarmuid McDonnell
#11/10/18
#This file scrapes trustee information from the Charity Commission website.

#######Import packages#######
from urllib.request import urlopen as uReq
from bs4 import BeautifulSoup as soup
from lxml.html import fromstring
from itertools import cycle
from datetime import datetime
import sys
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import downloaddate, longtime
from time import sleep
import requests
import glob
import pandas as pd
#import dropbox
import csv
import os
import io
import re
import numpy as np
from loggenerator import gen_log
from random import shuffle

#######Global params#######
sleeptime = 0 # Sleep time used when the scraper hits and erro
showalreadyscraped = 0 # Set to 1 to see already scraped charities in console window - runs faster when set to 0
proxyinterval = 600 # Number of seconds to wait before hitting proxy site again - when restarting an incomplete run it was just trying bad charities and hitting the proxy site over and over.

#######Functions#######
# Define a function for generating proxies
def get_proxies():
    url = 'https://free-proxy-list.net/'
    response = requests.get(url)
    parser = fromstring(response.text)
    proxies = set()
    for i in parser.xpath('//tbody/tr')[:10]:
    	if i.xpath('.//td[7][contains(text(),"no")]') or i.xpath('.//td[7][contains(text(),"yes")]'): # None on the list have yes at current time
            #Grabbing IP and corresponding PORT
            proxy = ":".join([i.xpath('.//td[1]/text()')[0], i.xpath('.//td[2]/text()')[0]])
            proxies.add(proxy)
    print('New proxies grabbed.\n')
    return proxies

#######Main program#######
"""
# Fetch Dropbox authentication
dbtokenpath = 'C:/Users/mcdonndz-local/Desktop/admin/db_token.txt'
#dbtokenpath_pi = '/home/pi/admin/dp_token.txt'
dbtokenfile = open(dbtokenpath, "r")
dbapitoken = dbtokenfile.read()
print(dbapitoken)

dbx = dropbox.Dropbox(dbapitoken) # Create an object for accessing Dropbox API
"""
log_starttime = longtime() # Get the current date

# Define paths
projpath = './' # Location of syntax
localdatapath = projpath + 'temp/' # The location of the input file changes based on the month it was downloaded - move it manually into this temp folder
if not os.path.exists(localdatapath): # If the paths don't exist, make them
    os.makedirs(localdatapath)
downloadpath = 'ew_download/Trustee_scrape'
if not os.path.exists(downloadpath):
    os.makedirs(downloadpath)

#Set the filenames
inputfile = localdatapath + 'extract_main_charity.csv' # This file is downloaded by ew_download.py
outputfilename = '/' + 'ew_trustee_data' + '.csv' # This is the main output data
outputfile = projpath + downloadpath + outputfilename
status = downloadpath + '/Status.txt' # Status is a text file which records the last charity which the scraper atempted to parse, can be used for debugging failue. This is automatically removed when the script completes.

print('\n>>> Run started') # Header of the output, with the start time.

# Create a panda's dataframe from the input CSV #
#pd.set_option('precision', 0)

with open(inputfile, 'rb') as f: # Open the input file
	df = pd.read_csv(f)

df['regno'] = df['regno'].fillna(0).astype(np.int64) # Remove decimals from regno

df.reset_index(inplace=True) 
df.set_index(['regno'], inplace=True) 
regno_list = df.index.values.tolist() # Make a list of all charity numbers from the input dataframe
print('Example regnumbers: ',regno_list[0:5])
print('Number of regnumbers: ',len(regno_list))
#shuffle(regno_list)

# Define variable names for the output files
if not os.path.exists(outputfile):
	varnames = ['Row ID', 'Execution time', 'FYE', 'Other Trusteeship', 'Link to Other Trusteeship Charity', 'Reason for Removal', 'Registered','Scrape time', 'Status code', 'Trustee Name', 'URL', 'Charity Number', 'Charity Name']
	with open(outputfile, 'a', newline='') as f:
		writer = csv.writer(f, varnames)
		writer.writerow(varnames)

# Define a counter to track how many rows of the input file the script processes
counter = 1

# Scrape proxies
proxytry = 1
try: #Call the get_proxies function and if it fails go to sleep and try again a up to 7 times
	proxies = get_proxies()
except:
	print('Trying to get proxies:',proxytry)
	sleep(sleeptime)
	proxies = get_proxies()
	proxytry = proxytry + 1
	if proxytry > 6:
		Print('>>> Failed to get proxies. Confirm site is up and relaunch script. <<<')
		quit()
previoustime = longtime() #Set time when proxies were first grabbed - this is used to stop the scraper repeatedly asking for new proxies 
print('Proxies:',proxies) 
proxy_pool = cycle(proxies)

prev_df = pd.read_csv(outputfile, encoding='cp1252') # Read in the output file to check for perviously scraped charities, this avoids double scraping and it means the script can be restarted from where it left off
prev_suc = prev_df['Charity Number'].tolist()

# Loop through list of charity numbers and scrape info from webpages
for ccnum in regno_list:

	if ccnum in prev_suc: # If have already seen the charity just ignore it
		if showalreadyscraped == 1:
			print(ccnum,'already scraped, moving on to next charity.')
			percdone = (counter)/len(regno_list)*100
			print("%.2f" % percdone, '% done\n')
		counter = counter + 1
		continue
	else:
		pass
	print('\nCharno:',ccnum)
	starttime = longtime() # Track how long it takes to scrape data for each charity

	# Define counter to track number of times the script tries to use a valid proxy
	proxytry = 1
	while proxytry < 10:
		try:
			proxy = next(proxy_pool) # Grab a proxy from the pool
			proxytry = 11
			#ccnum = 202843
			webadd = 'http://beta.charitycommission.gov.uk/charity-details/?regid=' + str(ccnum) +'&subid=0'
			headers = {'http': proxy, 'https': proxy, 'User-Agent': 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.106 Safari/537.36'} # Spoof the user-agent of the request to return the content seen by Chrome.
			# Define counter to track number of webpage request attempts; try three times
			
			attempt = 1
			while attempt < 4:
				rorg = requests.get(webadd, headers=headers) # Grab the page using the URL and headers.
				print(proxy) # Checks if script is cycling through proxies
				
				if rorg.status_code==200: # Only proceed if the webpage can be requested successfully
					attempt = 5
					html_org = rorg.text # Get the text elements of the page.
					soup_org = soup(html_org, 'html.parser') # Parse the text as a BS object.
					#print(soup_org)

					################################# Charity and Trustee info #################################

					if not soup_org.find('div', class_='pcg-charity-details__status-description pcg-charity-details__status-description--removed'): # If the charity isn't removed from the Register then proceed with scraping trustee info
						#try: # This try captures instances where the webpage request was successful but the result is blank page i.e. no charity information
						# Capture charity name
						charname = soup_org.find("h1", class_="pcg-charity-details__title").text
						print(charname)

						# Capture financial year end (FYE) the trustee information refers to
						fyetemp = soup_org.find('p', class_="pcg-charity-details__title-desc").text
						#print(fyetemp)
						try:
							fye = re.search('(?<=ending )(\d\d \w+ \d\d\d\d)', fyetemp).group(1) # Grab financial year using regex
							#print(fye)
						except:
							fye = 'No financial year on record, may be overdue.'
						
						# Capture trustee information
						boardinfo = soup_org.find("div", class_="table-responsive-sm") # Scrape the whole panel
						boardinfo = boardinfo.find_all('tr') # Find all the rows and store them as a list
						del boardinfo[0] # Delete the top line which is the headers
						#print(boardinfo[0])
						
						trustee = list(map(lambda x : x.find('td'), boardinfo)) # The name is in it's own tag so easy to find, map/lambda applies something to every item in a list
						righttrustee=[]
						for element in trustee:
							#print(element)
							if '\n\r\n' in element.text:
								pass
							else:
								righttrustee.append(element)

						#print('Trustees:',righttrustee) # keeping this !text for the moment becasue the rowspan is used below in working out which boards they are on, converted to pure text later
						
						otherboard = list(map(lambda x : x.find_all('a', href=True), boardinfo)) # This line just says for every item in the list find the tag with the networking links
						#print('otherboard',otherboard) # This is a flat lists of other boards
										
						other_trusteeships = []
						for el in otherboard:
							ot_text = list(map(lambda x : x.text, el)) # Extract the text
							ot_text = list(map(lambda x : x.replace('\t',''), ot_text)) #These three lines just remove the white space, t is tab, n is newline, r is return
							ot_text = list(map(lambda x : x.replace('\n',''), ot_text))
							ot_text = list(map(lambda x : x.replace('\r',''), ot_text))
							ot_text = list(map(lambda x : x.strip(), ot_text)) # Remove start and end white space 
					
							other_trusteeships.append(ot_text)
						#print('other_trusteeships:',other_trusteeships) # This is now processed but still flat - need to be linked up to the names
						
						# They have changed the coding of the site which makes it a right pain to link the people to the names and links
						realother_trusteeships=[] 
						for person in righttrustee:
							#print('person:',person)
							if 'rowspan' in str(person): # If the person has 'rowspan' in thier html tag then they are on another board, we can use the number to create a leveled list (but it's a bit complex)
								positions = re.search('(?<=rowspan=")(\d)', str(person)).group(1) # This regex searches for the number following 'rowspan'
								positions = int(positions)
								subrealother_trusteeships=[] # Create a sub list reconstruct the main list with levels
								while positions >0: # While each person has a position on another board to be assigned...
									#print('other_trusteeships:',other_trusteeships[0])
									stringelement = str(other_trusteeships[0]) # Grab the first item in the other charities list
									for char in ['[',']','\'']:
										stringelement = stringelement.replace(char,'') # Strip the list artefacts off
									subrealother_trusteeships.append(stringelement) # Add each to the sublist
									del other_trusteeships[0] # Delete the first element so when it cycles it will pick up the next
									positions = positions-1 # de-increment the posiitons number so it appends the correct number for each person
								realother_trusteeships.append(subrealother_trusteeships) # Append the sub list for each person
							else:
								positions=0
								del other_trusteeships[0]
								realother_trusteeships.append(['.']) # If they aren't a boardmember of another char then just add a null to the list to maintain lenght/position

						other_trusteeships_link=[] # Initialize list
						for link in otherboard:
							if link==[]:
								other_trusteeships_link.append([])
							else:
								for el in link:
									atag = el['href'] # Extract the link
									other_trusteeships_link.append([atag])

						realother_trusteeships_link=[] 
						for person in righttrustee:
							#print('person:',person)
							if 'rowspan' in str(person): # If the person has 'rowspan' in thier html tag then they are on another board, we can use the number to create a leveled list (but it's a bit complex)
								positions = re.search('(?<=rowspan=")(\d)', str(person)).group(1) # This regex searches for the number following 'rowspan'
								positions = int(positions)
								subrealother_trusteeships_link=[] # Create a sub list reconstruct the main list with levels
								while positions >0: # While each person has a position on another board to be assigned...
									#print('other_trusteeships:',other_trusteeships[0])
									stringelement = str(other_trusteeships_link[0]) # Grab the first item in the other charities list
									for char in ['[',']','\'']:
										stringelement = stringelement.replace(char,'') # Strip the list artefacts off
									subrealother_trusteeships_link.append(stringelement) # Add each to the sublist
									del other_trusteeships_link[0] # Delete the first element so when it cycles it will pick up the next
									positions = positions-1 # de-increment the posiitons number so it appends the correct number for each person
								realother_trusteeships_link.append(subrealother_trusteeships_link) # Append the sub list for each person
							else:
								positions=0
								del other_trusteeships_link[0]
								realother_trusteeships_link.append(['.']) # If they aren't a boardmember of another char then just add a null to the list to maintain lenght/position

						righttrustee = list(map(lambda x : x.text, righttrustee))
						
						# Data management #
						# Create variables capturing the number of trustees, number of other trusteeships per trustee, and adjust Row ID to begin at 1 
						capturetime = longtime() # Grab time
						executetime = capturetime-starttime
						# Write to JSON and CSV
						dicto = {'Status code':rorg.status_code,'Execution time':executetime, 'URL':webadd,'Scrape time':capturetime,'ccnum':ccnum,  'FYE': fye, 'charname': charname, 'Trustee':righttrustee, 'Other trusteeships':realother_trusteeships, 'Other trusteeships link': realother_trusteeships_link, 'Registered': '1', 'Reason for removal': '.'} # Store the new variables as a dictionary

						df_csv = pd.DataFrame(dicto)
						#print(df_csv)
						with open(outputfile, 'a', newline='') as f:
							df_csv.to_csv(f, header=False, encoding='cp1252')

						with open(status, 'w') as g: # Open a text writer called f. This is the status file which helps with debugging failed runs.
							g.write('Run not successfully finished, last charity number scraped was: ')
							g.write(str(ccnum))
							g.write('\n')
							g.write('Please restart the scraper. Do not delete the download file, it will append the new records.')	
						g.close()

						#except:
						#	print('\r')
						#	print('No information available for this charity | regno: ' + str(ccnum))
						#	print('\r')
					elif soup_org.find('div', class_='pcg-charity-details__status-description pcg-charity-details__status-description--removed'): # Charity has been removed and therefore trustee information does not exist
						print('>>> Charity removed <<<')
						#try: # This try captures instances where the webpage request was successful but the result is blank page i.e. no charity information
						remreason = soup_org.find('div', class_='pcg-charity-details__status-description pcg-charity-details__status-description--removed')
						remreason = remreason.text
						remreason = re.search('(?<=Reason for removal: )(.+)$', remreason).group(1)
												
						# Capture charity name
						charityname = soup_org.find('h1', class_='pcg-charity-details__title')
						charname = charityname.text
						print(charname)
						print(remreason)

						capturetime = longtime() # Grab time
						executetime = capturetime-starttime
						# Write to CSV
						dicto = {'Status code':rorg.status_code,'Execution time':executetime, 'URL':webadd,'Scrape time':capturetime,'ccnum':ccnum,  'FYE': '.', 'charname': charname, 'Trustee':'.', 'Other trusteeships':'.', 'Other trusteeships link': '.', 'Registered': '0', 'Reason for removal': remreason} # Store the new variables as a dictionary
						df_csv = pd.DataFrame(dicto, index=[1])
						with open(outputfile, 'a', newline='') as f:
							df_csv.to_csv(f, header=False, encoding='cp1252')
						#except:
							print('\r')
							print('No information available for this charity | regno: ' + str(ccnum))
							print('\r')
					print('Processed ' + str(counter) + ' rows in the input file for charity:', ccnum)
					percdone = ((counter)/len(regno_list))*100
					print("%.2f" % percdone, '% done')
					counter +=1
				else:
					print('\r')
					print(rorg.status_code, '| Could not resolve address of webpage')
					print('Will try to request webpage a couple more times')
					attempt = attempt+1	
		
		except Exception as e:
			print('>>>> Error:',e, '<<<<') # Some error occured
			sleep(sleeptime)
			currenttime = longtime() # work out how long since last scraped proxies
			deltatime = currenttime-previoustime
			#print(deltatime.total_seconds())
			if deltatime.total_seconds() > proxyinterval: # If havn't gotten new proxies in a while get them again
				try:
					proxies = get_proxies()
					previoustime = longtime()
				except:
					pass
			else:
				print('Not getting new proxies, too soon since last atempt.\n')
			#proxy_pool = cycle(proxies)
			proxy = next(proxy_pool)
			proxytry = proxytry+1
			

#Log file here
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'Scrape trustee network information form Charity Commisison website, this informaiton is not available in the data download perfomred in ew_download.py.'
processedfiles = inputfile # Get the input file details
savpath = downloadpath + '/' # Get where the script is saving its output files
writtenfiles = outputfile # Get list of created files
settings_toggles = {'sleeptime': sleeptime, 'showalreadyscraped': showalreadyscraped, 'proxyinterval': proxyinterval}
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles, str(settings_toggles)) # Pass info to log file generator

try:
    os.remove(status) # Remove the status text now the run is complete.
except OSError:
    pass

"""
# Upload files to Dropbox
infile = outputfile
outfile = downloadpath + 'ew_trustee_data_' + ddate + '.csv' # Dataset
loginfile = logoutputfile
logoutfile = remotelogpath + 'ew_trustee_log_' + ddate + '.csv' # Log file


with open(infile, 'rb') as f:
	#print(f.read())
	dbx.files_upload(f.read(), outfile, mute=True, mode=dropbox.files.WriteMode.overwrite)

with open(loginfile, 'rb') as f:
	dbx.files_upload(f.read(), logoutfile, mute=True, mode=dropbox.files.WriteMode.overwrite)	
"""
# Delete contents of localdatapath - NOT CURRENTLY WORKING
'''
try:
	os.remove(infile)
	print('Deleted local file')
except:
	print('Could not delete local file')
'''
print('\r')
print('>>> Finished <<<')
