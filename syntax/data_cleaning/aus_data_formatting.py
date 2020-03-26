# Script to Aus Charity Register from JSON to CSV
# Diarmuid McDonnell
# Created: 29 August 2019
# Last edited: captured in Github file history

# Import modules #

import json
import csv

print('Beginning script')

# Define paths
localdatapath = 'C:/Users/mcdonndz-local/Dropbox/mission_accomp/data_raw/aus/'
projpath = './' # Location of syntax

# Define file names and output paths
charregjson = 'auscharities_register_20190822.json'
charregcsv = 'auscharities_register_20190822.csv'

incharreg = localdatapath + charregjson # take in the json version
outcharreg = localdatapath + charregcsv # output the csv version


#Read JSON data into the regchar variable (i.e. a Python object)
with open(incharreg, 'r') as f:
	auschar = json.load(f)

print(len(auschar)) # Counts number of keys in the dictionary
print(len(auschar['result']))
#print(auschar['result'].keys()) # Looks like everything I need is in the 'result' key
#print(auschar['result'].values())
print('----------------------------------------------------')
print('                                                    ')
print('                                                    ')
#print(auschar['help'].values())
print('                                                    ')
print('                                                    ')
print('----------------------------------------------------')
print('                                                    ')
print('                                                    ')
#print(auschar['success'].values())

varnames = auschar['result']['records'][0].keys() # Extract the variable names from the dictionary keys of the first observation

# Write the results to a csv file #
'''
with open(outcharreg, 'w', newline='') as outCSVfile:

	dict_writer = csv.DictWriter(outCSVfile, varnames)
	dict_writer.writeheader()
	dict_writer.writerows(auschar['result']['records'])

print('Finished writing to csv!')	
'''