# NZ Charity data - Code areas
# Alasdair Rutherford
# Created: 2018
# Last edited: Github history - https://github.com/DiarmuidM/mission_accomp/tree/master/syntax/data_collection/nz
# Edited by Tom Wallace
# Description: The 'GrpOrgAllReturns' files contain a string list in column BA which details which regions each org operates in. This file uses a dictonary to code these into one of four values
# null = 0, local = 1, national = 2, international = 3
# These are then written to new versions of the 'GrpOrgAllReturns' files appended with '_geog.csv' as individual columns. The number of columns written depends on the maximum length of the areas list in each given year

#######Import packages#######
import csv
import sys
import os
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from downloaddate_function import longtime
from loggenerator import gen_log

#######Initialization#######
datapath = './data_raw/' # Data path

log_starttime = longtime() # When the script starts for the logfile

#######Main program#######
# This grayed out block of code reads in the dictonary of what region means which code from an external CSV called 'nz_AreaOfOperations_coded.csv'
# To make this script more portable this dictonary has been hardcoded below so this file isn't needed

#arealookup = datapath + "AreaOfOperations/nz_AreaOfOperations_coded.csv" # N.B. If this file is used it will need to have name = 'null' areacode = 0 added to it or the code below will fail when it hit's a charity with no recorded areas
#with open(arealookup, 'r', newline='') as arealookup_file:
#	reader_area = csv.reader(arealookup_file)
#	areadict={}
#	for row in reader_area:
#		areadict[row[1]] = row[3]
#		print(row[1], row[2])

# Dictonary of areas and codes
areadict = {'null': '0', 'Africa': '3', 'Antarctica': '3', 'Asia': '3', 'Auckland': '1', 'Bay of Plenty': '1', 'Canterbury': '1', 'Chatham Islands': '1', 'Europe': '1', 'Gisborne': '1', "Hawke's Bay": '1', 'Manawatu - Wanganui': '1', 'Nationwide': '2', 'Nelson - Marlborough - Tasman': '1', 'North America': '3', 'Northland': '1', 'Oceania': '1', 'Otago': '1', 'South America': '3', 'Southland': '1', 'Taranaki': '1', 'Waikato': '1', 'Wellington - Wairarapa': '1', 'West Coast': '1', 'Afghanistan': '3', 'Albania': '3', 'Algeria': '3', 'Andorra': '3', 'Angola': '3', 'Antigua and Barbuda': '3', 'Argentina': '3', 'Armenia': '3', 'Australia': '3', 'Austria': '3', 'Azerbaijan': '3', 'Bahamas': '3', 'Bahrain': '3', 'Bangladesh': '3', 'Barbados': '3', 'Belarus': '3', 'Belgium': '3', 'Belize': '3', 'Benin': '3', 'Bhutan': '3', 'Bolivia': '3', 'Bosnia and Herzegovina': '3', 'Botswana': '3', 'Brazil': '3', 'Brunei': '3', 'Bulgaria': '3', 'Burkina': '3', 'Burma (Myanmar)': '3', 'Burundi': '3', 'Cambodia': '3', 'Cameroon': '3', 'Canada': '3', 'Cape Verde': '3', 'Central African Republic': '3', 'Chad': '3', 'Chile': '3', 'China': '3', 'Colombia': '3', 'Comoros': '3', 'Congo': '3', 'Congo, Democratic Republic of': '3', 'Costa Rica': '3', 'Croatia': '3', 'Cuba': '3', 'Cyprus': '3', 'Czech Republic': '3', 'Denmark': '3', 'Djibouti': '3', 'Dominica': '3', 'Dominican Republic': '3', 'East Timor': '3', 'Ecuador': '3', 'Egypt': '3', 'El Salvador': '3', 'Equatorial Guinea': '3', 'Eritrea': '3', 'Estonia': '3', 'Ethiopia': '3', 'Fiji': '3', 'Finland': '3', 'France': '3', 'Gabon': '3', 'Gambia': '3', 'Georgia': '3', 'Germany': '3', 'Ghana': '3', 'Greece': '3', 'Grenada': '3', 'Guatemala': '3', 'Guinea': '3', 'Guinea-Bissau': '3', 'Guyana': '3', 'Haiti': '3', 'Honduras': '3', 'Hungary': '3', 'Iceland': '3', 'India': '3', 'Indonesia': '3', 'Iran': '3', 'Iraq': '3', 'Ireland': '3', 'Israel': '3', 'Italy': '3', 'Ivory Coast': '3', 'Jamaica': '3', 'Japan': '3', 'Jordan': '3', 'Kazakhstan': '3', 'Kenya': '3', 'Kiribati': '3', 'Korea, North': '3', 'Korea, South': '3', 'Kuwait': '3', 'Kyrgyzstan': '3', 'Laos': '3', 'Latvia': '3', 'Lebanon': '3', 'Lesotho': '3', 'Liberia': '3', 'Libya': '3', 'Liechtenstein': '3', 'Lithuania': '3', 'Luxembourg': '3', 'Macedonia': '3', 'Madagascar': '3', 'Malawi': '3', 'Malaysia': '3', 'Maldives': '3', 'Mali': '3', 'Malta': '3', 'Marshall Islands': '3', 'Mauritania': '3', 'Mauritius': '3', 'Mexico': '3', 'Micronesia': '3', 'Moldova': '3', 'Monaco': '3', 'Mongolia': '3', 'Montenegro': '3', 'Morocco': '3', 'Mozambique': '3', 'Namibia': '3', 'Nauru': '3', 'Nepal': '3', 'Netherlands': '3', 'New Zealand': '3', 'Nicaragua': '3', 'Niger': '3', 'Nigeria': '3', 'Norway': '3', 'Oman': '3', 'Pakistan': '3', 'Palau': '3', 'Panama': '3', 'Papua New Guinea': '3', 'Paraguay': '3', 'Peru': '3', 'Philippines': '3', 'Poland': '3', 'Portugal': '3', 'Qatar': '3', 'Romania': '3', 'Russian Federation': '3', 'Rwanda': '3', 'Saint Kitts and Nevis': '3', 'Saint Lucia': '3', 'Saint Vincent and the Grenadines': '3', 'Samoa': '3', 'San Marino': '3', 'Sao Tome and Principe': '3', 'Saudi Arabia': '3', 'Senegal': '3', 'Serbia': '3', 'Seychelles': '3', 'Sierra Leone': '3', 'Singapore': '3', 'Slovakia': '3', 'Slovenia': '3', 'Solomon Islands': '3', 'Somalia': '3', 'South Africa': '3', 'South Sudan': '3', 'Spain': '3', 'Sri Lanka': '3', 'Sudan': '3', 'Suriname': '3', 'Swaziland': '3', 'Sweden': '3', 'Switzerland': '3', 'Syria': '3', 'Tajikistan': '3', 'Tanzania': '3', 'Thailand': '3', 'Togo': '3', 'Tonga': '3', 'Trinidad and Tobago': '3', 'Tunisia': '3', 'Turkey': '3', 'Turkmenistan': '3', 'Tuvalu': '3', 'Uganda': '3', 'Ukraine': '3', 'United Arab Emirates': '3', 'United Kingdom': '3', 'United States': '3', 'Uruguay': '3', 'Uzbekistan': '3', 'Vanuatu': '3', 'Vatican City': '3', 'Venezuela': '3', 'Vietnam': '3', 'Yemen': '3', 'Zambia': '3', 'Zimbabwe': '3', 'Niue': '3'}

inputfilepath=[] # Initialize list of input files for the log file
outputfilename_list=[]

for year in range(2007, 2020): # 2007 to 2019 

	print('\nYear:', year)

	infilename = datapath + 'GrpOrgAllReturns/' + 'GrpOrgAllReturns_yr' + str(year) + '_integrity.csv'
	#infilename = datapath + "GrpOrgAllReturns/GrpOrgAllReturns_yr" + str(year) + "_integrity.csv" # This is each datafile to be read
	maxlen = 1 # Initialize a maximum length counter variable outside of the loop
	with open(infilename, 'r', newline='') as returnforcoding_file: # This block of code counts the maximum number of areas of operation selected by a charity in each year file so that the output file can have the coorect number of headings (this is applied later one)
		reader = csv.reader(returnforcoding_file) # It was nessisary to open the input file twice (here and below) to avoid iteration errors
		for row in reader: # Get a list of areas for each row
			areas = row[52].split(",") # 53 is column BA in each input file
			lengthcorrected = len(areas) # for each row grab the length of the areas list
			if any('Democratic Republic of' in s for s in areas): # take one off if it's the DRC as it counts as 2
				lengthcorrected = lengthcorrected - 1
			koreanum = 0 # Korea can appear 0, 1 or 2 times so need to count the number of occurences and remove that many from the length as each entry counts 2 becasue of it's comma 'Korea, south'
			for each in areas:
				if 'Korea' in each:
					koreanum = koreanum + 1
			lengthcorrected = lengthcorrected - koreanum

			if lengthcorrected > maxlen: # Keep a running max for each year
				maxlen = lengthcorrected

	with open(infilename, 'r', newline='') as returnforcoding_file: # Open the file to iterate through again
		reader = csv.reader(returnforcoding_file)

		outfilename = datapath + 'GrpOrgAllReturns/' + 'GrpOrgAllReturns_yr' + str(year) + '_integrity_geog.csv' # Set the name for the output file 
		#outfilename = datapath + "GrpOrgAllReturns/GrpOrgAllReturns_yr" + str(year) + "_integrity_geog.csv" # Set the name for the output file 
		with open(outfilename, 'w', newline='') as outputcoded_file:
			writer = csv.writer(outputcoded_file)
			geogwriter = [] # Create a list of strings to make column headers
			for x in range(1,maxlen+1): # For each value from 1 to the maximum for each file...
				geogentry = 'geog' + str(x) # Make a string with the value on the end
				geogwriter.append(geogentry) # Add it into the list
			writer.writerow(reader.__next__() + geogwriter) # Write the list as column headers bespoke to each file

			for row in reader:
				areas = row[52].split(",") # 53 is column BA of the input files
				geoglist = []
				for place in areas: # Deal with the Koera and DRC again, but this time actually modify the lists. This could also be done before the list is made with regex, might make the code slightly simpler but no real advantage.
					geog = place.strip()
					if geog == 'Korea':
						geog = geog + ',' + areas[areas.index(place)+1]
					if geog == 'Congo':
						geog = geog + ', ' + 'Democratic Republic of'				
					if geog == 'South' or geog == 'North' or geog=='Democratic Republic of' or geog=='.' or geog=='':
						pass
					else:
						print('geog:',geog, end='')
						print('					', areadict[geog])
						geoglist.append(areadict[geog])
				writer.writerow(row + geoglist) # For each row write the row and then the individually contructed areas list

	inputfilepath.append(infilename)
	outputfilename_list.append(outfilename)


#Log generator
finishtime = longtime() # Get ending time
scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
scriptdesc = 'This script takes the region each charity says it operates in from field "BA" and codes them into one of four numbers based on if the region is local, national, international, or null.'
processedfiles = inputfilepath # Get the input file details
writtenfiles = outputfilename_list # Get list of created files
gen_log(log_starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles) # Pass info to log file generator

print('\nAll done!')