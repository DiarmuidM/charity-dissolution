# Script to search and download Charity Register from ACNC API and annual returns submitted to ACNC 2013 onwards
# Diarmuid McDonnell
# Created: 26 February 2018
# Last edited: captured in Github file history

# Import packages #

from datetime import datetime as dt
from bs4 import BeautifulSoup as soup
import requests
import os
import argparse
import json
import csv
import pandas as pd


# Define functions #

# Test #

def test(**args):
    print("\r")
    print("Welcome to this data collection script. Here is a list of functions you can run using this script: ")
    print("\r")
    print("* roc_download - downloads the latest copy of the Austrlian Charity Register")
    print("* webid_download - download a website id for a given charity")
    print("* webid_download_from_file - download website ids for a list of charities stored in a file")


# Download Register of Charities

def roc_download(**args):

    print("Downloading Australian Charity Register")
    print("\r")


    # Create folders

    try:
        os.mkdir("roc")
        os.mkdir("roc/logs")
        os.mkdir("masterfiles")
    except OSError as error:
        print(error)
        print("Folders already exist")    


    # Define output files

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    mfile = "./roc/logs/aus-roc-metadata-" + ddate + ".json"
    outfile = "./roc/aus-roc-" + ddate + ".xlsx" # Charity Register


    # Request file
    
    response = requests.get("https://data.gov.au/data/dataset/b050b242-4487-4306-abf5-07ca073e5594/resource/eb1e6be4-5b13-4feb-b28e-388bf7c26f93/download/datadotgov_main.xlsx")
    print(response.status_code, response.headers)


    # Save files (data and metadata)

    if response.status_code==200: # if the file was successfully requested
        
        # Metadata

        with open(mfile, "w") as f:
            f.write(json.dumps(dict(response.headers)))

        # Data

        if os.path.isfile(outfile): # do not overwrite existing file
            print("File already exists, no need to overwrite")
        else: # file does not currently exist, therefore create
            with open(outfile, "wb") as f:
                f.write(response.content)
        
        print('\r')    
        print('Successfully downloaded Charity Register')

    else: # file was not successfully requested
        print('\r')    
        print('Unable to download Charity Register')

    
    # Create master list of ABNs (CSV format)

    masterfile = "./masterfiles/aus-abn-master.csv" # List of ABNs

    roc = pd.read_excel(outfile, index_col=None)
    roc = roc[["ABN", "Charity_Legal_Name", "Registration_Date"]] # keep subset of columns
    roc_list = roc["ABN"].values.tolist() # convert ABN column to a list
    roc.columns = map(str.lower, roc.columns) # convert column names to lower case

    if not os.path.isfile(masterfile): # if master file doesn't exist, create it
        roc.to_csv(masterfile, index=False)

    else: # it exists, so append new observations to it
        master = pd.read_csv(masterfile, encoding = "ISO-8859-1", index_col=False)
        roc = roc.merge(master, on="abn", how="left", indicator=True, suffixes=("", "_y"))
        roc_new = roc.loc[roc["_merge"]=="left_only"]
        roc_new = roc_new[["abn", "charity_legal_name", "registration_date"]] # keep subset of columns

        if len(roc_new) > 0: # if there are new observations, then write to master list
            roc_new.to_csv(masterfile, mode="a", header=False, index=False)
        else: # if there are no new observations, then continue
            pass    


    print("\r")
    print("Charity Register: '{}'; and master file: '{}'".format(outfile, masterfile))



# Collect ACNC web ids for charities

def webid_download(abn: str, **args) -> tuple:
    """
        Downloads a charity's ACNC web id i.e., its unique identifier
        on the Regulator's website.
    """  

    # Request web page

    if not session:
        session = requests.Session()

    webadd = 'https://www.acnc.gov.au/charity?name_abn%5B0%5D=' + str(abn) 
    response = session.get(webadd)
    print(response.status_code, response.headers)

    
    # Parse web page

    html_org = response.text # Get the text elements of the page.
    soup_org = soup(html_org, "html.parser") # Parse the text as a BS object.

    if soup_org.find('td', {'class': 'views-field views-field-acnc-search-api-title-sort'}):
        charlinkdetails = soup_org.find('td', {'class': 'views-field views-field-acnc-search-api-title-sort'})
        charlink = charlinkdetails.find('a').get('href')
        webid = charlink[9:] # ignore string "charity"
        success = 1

    else:
        webid = "" 
        success = 0

    return webid, success       
 
    
def webid_download_from_file(infile="./masterfiles/aus-abn-master.csv", **args):
    """
        Takes a CSV file containing ABN numbers, extracts them, and returns a file containing
        a webid for each ABN.
    """

    print("Downloading Australian Charity Web IDs")
    print("\r")

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    
    # Create folders

    try:
        os.mkdir("webids")
        os.mkdir("webids/logs")
        os.mkdir("masterfiles")
    except OSError as error:
        print(error)
        print("Folders already exist")  
   

    # Define file to save results

    masterfile = "./masterfiles/aus-webids-master.csv" # master file of webids


    # Read in data

    roc = pd.read_csv(infile, encoding = "ISO-8859-1", index_col=False) # import file
    roc["ABN"] = roc["ABN"].fillna(0).astype(int) # deal with missing values and decimals
    roc_list = roc["ABN"].values.tolist() # convert ABN column to a list


    # Request web pages

    if os.path.isfile(masterfile): # if master file exists, we only need to look for webids for charities not in this file
        
        master = pd.read_csv(masterfile, encoding = "ISO-8859-1", index_col=False)
        master["abn"] = master["abn"].fillna(0).astype(int) # deal with missing values and decimals
        master_list = master["abn"].values.tolist() # convert ABN column to a list

        roc_set = set(roc_list)
        master_set = set(master_list)
        new_list = list(roc_set.difference(master_set)) # return a new list containing charity ids not in the master list

        for abn in new_list:
            webid, success = webid_download(abn) # call function

            with open(masterfile, "a", newline="") as f: # write results of function to file
                row = abn, webid, success
                writer = csv.writer(f)
                writer.writerow(row)


    else: # master file does not exist, create it and then execute function
       
        headers = ["abn", "webid", "success"]
        with open(masterfile, "w", newline="") as f: # write results of function to file
            writer = csv.writer(f, headers)
            writer.writerow(headers)
        
        for abn in roc_list:
            webid, success = webid_download(abn)

            with open(masterfile, "a", newline="") as f: # write results of function to file
                row = abn, webid, success
                writer = csv.writer(f)
                writer.writerow(row)

    print("\r")
    print("Please check the '{}' and '{}' folders for your files".format(outfile, masterfile))



# Main program #

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Download Australian Charity Data")
    parser.add_argument("-v", "--verbose", action='store_true', help="More descriptive output")

    subparsers = parser.add_subparsers(help="Operation to perform")

    test_parser = subparsers.add_parser("test", help="Test to check script is running")
    test_parser.set_defaults(func=test)

    roc_parser = subparsers.add_parser("roc", help="Download latest copy of Charity Register")
    roc_parser.set_defaults(func=roc_download)

    webid_parser = subparsers.add_parser("webids", help="Fetch ACNC web id of a charity")
    webid_parser.add_argument("abn", help="Australian Business Number of charity")
    webid_parser.set_defaults(func=webid_download)

    webid_file_parser = subparsers.add_parser("webids_file", help="Fetch ACNC web ids from a file")
    webid_file_parser.add_argument("infile", help="Location of file containing list of ABNs", default="./masterfiles/aus-abn-master.csv")
    webid_file_parser.set_defaults(func=webid_download_from_file)

    args = parser.parse_args()
    args.func(**args.__dict__)