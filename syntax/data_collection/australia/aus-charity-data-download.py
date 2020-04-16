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
    """
        Function that is used to test whether virtual environment is configured correctly.

        Dependencies:
            - NONE

        Issues:
    """

    print("\r")
    print("Welcome to this data collection script. Here is a list of functions you can run using this script: ")
    print("\r")
    print("* roc_download - downloads the latest copy of the Austrlian Charity Register")
    print("* webid_download - download a website id for a given charity")
    print("* webid_download_from_file - download website ids for a list of charities stored in a file")


# Download Register of Charities

def roc_download(**args):
    """
        Downloads latest copy of the Register of Charities.

        Dependencies:
            - NONE

        Issues: 
    """  

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

        Takes one argument:
            - Australian Business Number of a charity

        Dependencies:
            - roc_download 

        Issues: 
    """  

    # Request web page

    if not session:
        session = requests.Session()

    webadd = "https://www.acnc.gov.au/charity?name_abn%5B0%5D=" + str(abn) 
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

    print("Finished collecting webid of charity: {}".format(abn))

    return webid, success       


# Collect ACNC web ids for charities - from file

def webid_download_from_file(infile="./masterfiles/aus-abn-master.csv", **args):
    """
        Takes a CSV file containing ABN numbers, extracts them, and returns a file containing
        a webid for each ABN.

        Takes one arguments:
            - CSV file containing a list of abns for Australian charities

        Dependencies:
            - roc_download 

        Issues:
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
    print("Webid file: '{}'; and master file: '{}'".format(outfile, masterfile))



# Download ACNC web pages of charities #

def webpage_download(webid: str, abn: str, **args):
    """
        Downloads a charity's web page from the ACNC website, which can be parsed at a later date.

        Takes two arguments:
            - website id of charity i.e., its unique identifier on the regulator's website
            - abn of charity, which is its unique organisational id

        Dependencies:
            - webid_download | webid_download_from_file 

        Issues:
            - does not deal with cases where a charity has more than one web page (e.g., lots of trustees)    
    """

    print("Downloading Australian Charity Web Pages")
    print("\r")

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    
    # Create folders

    try:
        os.mkdir("webpages")
        os.mkdir("webpages/logs")
    except OSError as error:
        print(error)
        print("Folders already exist")

    
    # Request web page

    session = requests.Session()

    webadd = "https://www.acnc.gov.au/charity/" + str(webid) 
    response = session.get(webadd)

    
    # Parse web page

    if response.status_code==200:
        html_org = response.text # Get the text elements of the page.
        # soup_org = soup(html_org, "html.parser") # Parse the text as a BS object.


        # Save results to file

        outfile = "./webpages/aus-charity-" + str(abn) + "-" + ddate + ".txt"
        with open(outfile, "w") as f:
            f.write(html_org)

        print("Downloaded web page of charity: {}".format(abn))    
        print("\r")
        print("Web page file is here: '{}'".format(outfile))

    else:
        print("\r")
        print("Could not download web page of charity: {}".format(abn))



# Download ACNC web pages of charities - from file #

def webpage_download_from_file(infile="./masterfiles/aus-webids-master.csv", **args):
    """
        Takes a CSV file containing webids for Australian charities and
        downloads a charity's web page from the ACNC website, which can be parsed at a later date.

        Takes one argument:
            - CSV file containing a list of abns and webids for Australian charities

        Dependencies:
            - webid_download | webid_download_from_file 

        Issues:
            - does not deal with cases where a charity has more than one web page (e.g., lots of trustees)
    """

    print("Downloading Australian Charity Web Pages")
    print("\r")

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date

    
    # Create folders

    try:
        os.mkdir("webpages")
        os.mkdir("webpages/logs")
    except OSError as error:
        print(error)
        print("Folders already exist") 
   
   
    # Read in data

    df = pd.read_csv(infile, encoding = "ISO-8859-1", index_col=False) # import file


    # Request web pages

    for row in df.itertuples():
        webid = getattr(row, "webid")
        abn = getattr(row, "abn")
        webpage_download(webid, abn)

    print("\r")
    print("Finished downloading web pages from file: {}".format(infile))



# History Data #

def history(source="./webpages/", **args):
    """
        Takes a charity's webpage (.txt file) downloaded from the ACNC website and
        extracts the history of the organisation:
            - registration
            - enforcement
            - subtype (i.e., charitable purpose)

        Takes one argument:
            - A directory with .txt files containing HTML code of a charity's ACNC web page

        Dependencies:
            - webpage_download | webpage_download_from_file 

        Issues:
            - duplicates the information for the final charity in the loop  [SOLVED]     
    """

    # Create folders
    
    try:
        os.mkdir("history")
        os.mkdir("history/logs")
    except OSError as error:
        print(error)
        print("Folders already exist") 

    ddate = dt.now().strftime("%Y-%m-%d") # get today's date
    

    # Define output files

    enffile = "./history/aus-enforcement-" + ddate + ".csv"
    subfile = "./history/aus-subtype-" + ddate + ".csv"
    regfile = "./history/aus-registration-" + ddate + ".csv"

   
    # Define variable names for the output files
    
    evarnames = ["abn", "enforcement", "enforcement_date", "summary", "variation", "variation_date", "report", "note"]
    rvarnames = ["abn", "status_date", "status", "note"]
    svarnames = ["abn", "purpose", "start_date", "end_date", "note"]


    # Write headers to the output files

    with open(enffile, "w", newline="") as f:
        writer = csv.writer(f, evarnames)
        writer.writerow(evarnames)

    with open(regfile, "w", newline="") as f:
        writer = csv.writer(f, rvarnames)
        writer.writerow(rvarnames)  

    with open(subfile, "w", newline="") as f:
        writer = csv.writer(f, svarnames)
        writer.writerow(svarnames)
    

    # Read data

    for file in os.listdir(source):
        if file.endswith(".txt"):
            abn = file[12:23] # extract abn from file name
            f = os.path.join(source, file)
            with open(f, "r") as f:
                data = f.read()
                soup_org = soup(data, "html.parser") # Parse the text as a BS object.
            

            # Extract specific pieces of information: registration, enforcement, charitable purpose

            # Enforcement

            enfdetails = soup_org.find("div", class_="field field-name-acnc-node-charity-compliance-history field-type-ds field-label-hidden")      
            """
                Groups have an Enforcement section on their webpage; they do not for registration or subtype.
            """

            if enfdetails.find("div", class_="view-empty"): # If there is no enforcement history
                with open(enffile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "NULL", "NULL", "NULL", "NULL", "No enforcement history"
                    writer = csv.writer(f)
                    writer.writerow(row)

            elif enfdetails.find("div", class_="view-content"):
                enfcontent = enfdetails.find("div", class_="view-content")
                enftable = enfcontent.find("tbody").find_all("tr")
               
                for row in enftable:
                    td_list = row.find_all("td")
                    enftype = td_list[0].text.strip() # Type of enforcement
                    enfdate = td_list[1].text.strip() # Date of enforcement
                    enfsummary = td_list[2].text.strip() # Text summary of enforcement
                    enfvar = td_list[3].text.strip() # Variation in enforcement
                    enfvardate = td_list[4].text.strip() # Date of variation in enforcement
                    enfrep = td_list[5].find("a").get("href") # Link to enforcement report
                    note = "NULL"
                    row = abn, enftype, enfdate, enfsummary, enfvar, enfvardate, enfrep, note
                    print(row)  
                    with open(enffile, "a", newline="") as f:
                        writer = csv.writer(f)
                        writer.writerow(row)

            else: # Couldn't find enforcement details
                with open(enffile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "NULL", "NULL", "NULL", "NULL", "Could not find enforcement information on web page"
                    writer = csv.writer(f)
                    writer.writerow(row)

            
            # Registration and revocation

            revdetails = soup_org.find("div", class_="field field-name-acnc-node-charity-status-history field-type-ds field-label-hidden")

            if soup_org.find("div", class_="group-info field-group-div"): # If charity is part of a group
                with open(regfile, "a", newline="") as f:
                    row = abn, "NULL ", "NULL", "Group charity"
                    writer = csv.writer(f)
                    writer.writerow(row)
                continue          

            elif revdetails.find("div", class_="view-empty"): # If there is no registration history
                with open(regfile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "No status information found"
                    writer = csv.writer(f)
                    writer.writerow(row)

            elif revdetails.find("div", class_="view-content"): # if there is a registration history
                revcontent = revdetails.find("div", class_="view-content")
                revtable = revcontent.find("tbody").find_all("tr")
                
                for row in revtable:
                    td_list = row.find_all("td")
                    # Get relevant tds and write to output file
                    revdate = td_list[0].text.strip() # Effective date
                    revstatus = td_list[1].text.strip() # Status
                    note = "NULL"
                    row = abn, revdate, revstatus, note
                    with open(regfile, "a", newline="") as f:
                        writer = csv.writer(f)
                        writer.writerow(row)

            else: # Could not find registration and revocation details
                with open(subfile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "NULL", "Could not find registration and revocation information on web page"
                    writer = csv.writer(f)
                    writer.writerow(row)            


            # Purposes

            subdetails = soup_org.find("div", class_="field field-name-acnc-node-charity-subtype-history field-type-ds field-label-hidden")

            if soup_org.find("div", class_="group-info field-group-div"): # If charity is part of a group
                with open(subfile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "NULL", "Group charity"
                    writer = csv.writer(f)
                    writer.writerow(row)
                continue                     

            elif subdetails.find("div", class_="view-empty"): # If there is no subtype history
                with open(subfile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "NULL", "No subtype history"
                    writer = csv.writer(f)
                    writer.writerow(row)

            elif subdetails.find("div", class_="view-content"):
                subcontent = subdetails.find("div", class_="view-content")
                subtable = subcontent.find("tbody").find_all("tr")
               
                for row in subtable:
                    td_list = row.find_all("td")
                    subtype = td_list[0].text.strip() # Type of purpose
                    sdate = td_list[1].text.strip() # Start date of purpose
                    edate = td_list[2].text.strip() # End date of purpose
                    if edate == "—":
                        edate = edate.replace("—", "NULL")
                    note = "NULL"
                    row = abn, subtype, sdate, edate, note 
                    with open(subfile, "a", newline="") as f:
                        writer = csv.writer(f)
                        writer.writerow(row)

            else: # Couldn't find purpose details
                with open(subfile, "a", newline="") as f:
                    row = abn, "NULL", "NULL", "NULL", "Could not find subtype information on web page"
                    writer = csv.writer(f)
                    writer.writerow(row)




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

    webid_file_parser = subparsers.add_parser("webids_file", help="Fetch ACNC web ids - from a file")
    webid_file_parser.add_argument("infile", help="Location of file containing list of ABNs", default="./masterfiles/aus-abn-master.csv")
    webid_file_parser.set_defaults(func=webid_download_from_file)

    webpage_parser = subparsers.add_parser("webpages", help="Fetch ACNC web page of charity and save as a .txt file")
    webpage_parser.add_argument("webid", help="ACNC web id of charity")
    webpage_parser.add_argument("abn", help="Australian Business Number of charity")
    webpage_parser.set_defaults(func=webpage_download)

    webpage_file_parser = subparsers.add_parser("webpages_file", help="Fetch ACNC web page of charity - from a file")
    webpage_file_parser.add_argument("infile", help="Location of file containing list of ACNC webids for charities", default="./masterfiles/aus-webids-master.csv")
    webpage_file_parser.set_defaults(func=webpage_download_from_file)

    history_parser = subparsers.add_parser("history", help="Fetch history of charity from ACNC web page (.txt file")
    history_parser.add_argument("source", help="Location of .txt files containing ACNC web pages", default="./webpages/")
    history_parser.set_defaults(func=history)

    args = parser.parse_args()
    args.func(**args.__dict__)