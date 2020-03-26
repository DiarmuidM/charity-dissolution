## Python script to unzip and convet data files downloaded by 'ew_download.py'

# Created by: NCVO
# Created: ?
# Last edited: captured in Github file history
# Edited by Tom Wallace

#######Import packages#######
import zipfile
import sys
import csv
sys.path.insert(0, './Functions_scripts') # Allows to set a different path for the scripts being called below (but only if it branches off of the root dir)
from loggenerator import gen_log
from downloaddate_function import downloaddate, longtime
import re
import os

#######Program#######
cc_files = {
    "extract_acct_submit": [
      "regno",
      "submit_date",
      "arno",
      "fyend"
    ],
    "extract_aoo_ref": [
      "aootype",
      "aookey",
      "aooname",
      "aoosort",
      "welsh",
      "master"
    ],
    "extract_ar_submit": [
      "regno",
      "arno",
      "submit_date"
    ],
    "extract_charity": [
      "regno",
      "subno",
      "name",
      "orgtype",
      "gd",
      "aob",
      "aob_defined",
      "nhs",
      "ha_no",
      "corr",
      "add1",
      "add2",
      "add3",
      "add4",
      "add5",
      "postcode",
      "phone",
      "fax",
    ],
    "extract_charity_aoo": [
      "regno",
      "aootype",
      "aookey",
      "welsh",
      "master"
    ],
    "extract_class": [
      "regno",
      "class"
    ],
    "extract_class_ref": [
      "classno",
      "classtext",
    ],
    "extract_financial": [
      "regno",
      "fystart",
      "fyend",
      "income",
      "expend"
    ],
    "extract_main_charity": [
      "regno",
      "coyno",
      "trustees",
      "fyend",
      "welsh",
      "incomedate",
      "income",
      "grouptype",
      "email",
      "web"
    ],
    "extract_name": [
      "regno",
      "subno",
      "nameno",
      "name"
    ],
    "extract_objects": [
      "regno",
      "subno",
      "seqno",
      "object"
    ],
    "extract_partb": [
      "regno",
      "artype",
      "fystart",
      "fyend",
      "inc_leg",
      "inc_end",
      "inc_vol",
      "inc_fr",
      "inc_char",
      "inc_invest",
      "inc_other",
      "inc_total",
      "invest_gain",
      "asset_gain",
      "pension_gain",
      "exp_vol",
      "exp_trade",
      "exp_invest",
      "exp_grant",
      "exp_charble",
      "exp_gov",
      "exp_other",
      "exp_total",
      "exp_support",
      "exp_dep",
      "reserves",
      "asset_open",
      "asset_close",
      "fixed_assets",
      "open_assets",
      "invest_assets",
      "cash_assets",
      "current_assets",
      "credit_1",
      "credit_long",
      "pension_assets",
      "total_assets",
      "funds_end",
      "funds_restrict",
      "funds_unrestrict",
      "funds_total",
      "employees",
      "volunteers",
      "cons_acc",
      "charity_acc"
    ],
    "extract_registration": [
      "regno",
      "subno",
      "regdate",
      "remdate",
      "remcode"
    ],
    "extract_remove_ref": [
      "code",
      "text"
    ],
    "extract_trustee": [
      "regno",
      "trustee"
    ]
}


def to_file(bcpdata, savefolder, csvfilename='converted.csv', col_headers=None):

    extractpath = './ew_download/' + savefolder + '/data_extracted/'
    csvfilename_path = extractpath + csvfilename
    with open(csvfilename_path, 'w', encoding='utf-8') as csvfile:
        if(col_headers):
            for c in col_headers:
                c = c
            writer = csv.writer(csvfile, lineterminator='\n')
            writer.writerow(col_headers)
        csvfile.write(bcpdata)

    return extractpath

def import_zip(zip_file):
    starttime = longtime()
    zf = zipfile.ZipFile(zip_file, 'r')
    print('Opened zip file: %s' % zip_file)
    try:
      savefolder = re.search('ew_download\/(.+?)\/data_raw', zip_file).group(1) # Find the month the data relates to with regex
    except:
      print('>>> Path error, killing script <<<')
      quit() # If can't find a month then end the script and poke the user to investigate
    log_output_filename = [] # This captures all files saved for the log file
    for filename in cc_files:
      try:
          check_filename = filename + '.bcp'
          csv_filename = filename + '.csv'
          # check whether there is a file in the
          for i in zf.namelist():
              if i[-len(check_filename):]==check_filename:
                  bcp_filename = i

          bcpdata = zf.read(bcp_filename)
          bcpdata = bcpdata.decode('utf-8', errors="replace")
          lineterminator='*@@*'
          delimiter='@**@'
          quote='"'
          newdelimiter=','
          escapechar='\\'
          newline='\n'
          bcpdata = bcpdata.replace(escapechar, escapechar + escapechar)
          bcpdata = bcpdata.replace(quote, escapechar + quote)
          bcpdata = bcpdata.replace(delimiter, quote + newdelimiter + quote)
          bcpdata = bcpdata.replace(lineterminator, quote + newline + quote)
          bcpdata = quote + bcpdata + quote
          extractpath = to_file(bcpdata, savefolder, csvfilename=csv_filename, col_headers=cc_files[filename])

          outputfilename  = extractpath + csv_filename
          log_output_filename.append(outputfilename) # Grab the name of each file for the log
          print('Converted: %s' % bcp_filename)
      except KeyError:
          print('ERROR: Did not find %s in zip file' % bcp_filename)
    
    #Logfile
    finishtime = longtime() # Get ending time
    scriptname = os.path.basename(__file__) # Get the current scriptname as a variable
    scriptpath = (os.path.dirname(os.path.realpath(__file__))) # Get the absolute dir the script is in
    scriptdesc = 'Unzips the files downloaded by ew_download and writes them out as separate CSVs calling bcp.py to convert.'
    processedfiles = zip_file # Get the input file details
    writtenfiles = log_output_filename # Get list of created files
    gen_log(starttime, finishtime, scriptname, scriptpath, scriptdesc, processedfiles, writtenfiles) # Pass info to log file generator

def main():
    #zip_file = sys.argv[1]
    zip_file = './ew_download/Mar2019/data_raw/cc_CharityRegister_20190410.zip' # temporary path so can be called without re-downloading the data
    import_zip(zip_file)

if __name__ == '__main__':
	main()