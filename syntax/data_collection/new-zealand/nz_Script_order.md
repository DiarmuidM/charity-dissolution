nz_download.py is the master file. This downloads the data from the web and then calls the other 4 scripts to process it. The other scripts are not just shells for functions and can be run stand-alone, but this should be unnecessary. The master file has toggles for the processing scripts, to aid in debugging, but they must be run in order becasue each feeds into the next.

#Script order 
nz_download.py (master) > nz_regroupfilesbyyear.py > nz_checkintegrity.py > nz_codeareas.py > nz_coderegistration.py