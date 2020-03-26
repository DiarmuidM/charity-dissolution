
## Python master script that runs all of the data collection scripts for the ISTR 2018 paper

from time import sleep
import os
import os.path
from downloaddate_function import downloaddate
import subprocess


# Get today's date
ddate = downloaddate()	
print('The date is ' + ddate)


# Run python scripts in order:

import istr_ew_download
print('Finished executing istr_ew_download.py')
print('                                             ')
print('---------------------------------------------')
print('                                             ')
sleep(10)

import istr_aus_download
print('Finished executing istr_aus_download.py')
print('                                             ')
print('---------------------------------------------')
print('                                             ')
sleep(10)

import istr_nz_download
sleep(10)
print('Finished executing istr_nz_download.py')
print('                                                  ')
print('                                                  ')
print('                                                  ')
print('                                                  ')
print('All of the python scripts have been executed on ' + ddate + '. Go see the data folder for proof they have worked.')
print('                                                  ')
print('                                                  ')
print('                                                  ')
print('                                                  ')
'''

# Run Stata syntax #

## See repire project for the code to do this.