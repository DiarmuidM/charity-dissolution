ew_download.py calls fimport.py - fimport does not need to be run on its own.

ew_scrape uses data downloaded by ew_download.py but does not call the script itself, run ew_download.py frist. Manually copy 'extract_main_charity.csv' into the temp folder created by ew_scrape.py

ew_charitybase.py is completely separate.