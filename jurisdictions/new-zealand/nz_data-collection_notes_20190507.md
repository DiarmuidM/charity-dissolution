# Mission Accomplished? A Cross-national Examination of Charity Dissolution

## Data Collection [April - June 2019]

## New Zealand

### Notes
Regulator needs to sanitise double quotes and commas form strings. The way we are downloading (by copying entire objects and streaming them to csv) means we can't escape these on our end which leads to integrity errors. It may be possible to use another data type to stream the data down which would act as an intermediate and allow escaping when writing the CSVs. If this was the case it would remove the need for 'nz_checkintegrity.py'

### Dates
There are a number of errors in the date fields, notably the dates used to contrsuct the individual 'GrpOrgAllReturns' (column: yearended) and 'vOfficerOrganisations' (column: PositionAppointmentDate) files. If this causes a problem for analysis then most could be automatically fixed by a custom fucntion with the remaining being flagged or dropped.  

### Scripts
##### 'nz_download.py'
This script downloads all available New Zealand charity data by making requests for different slices of data and streaming them into csv files. This script can take some time (around an hour on average) to run and does occasionally fail which happens when the regulator site repeatedly closes the connection. There doesn’t seem to be an elegant way to defend against this so just run the script again if it hangs for more than a few hours.

This file also serves as the master file and calls the 4 data processing scripts detailed below, these can be toggled on or off for debugging but must pipeline in to each other. All set to true is the default.

Once the data is downloaded it is sensible to set download_toggle to 'False' if the processing scripts need to be rerun or changed - there is no need to wait for the data to download again and doing it repeatedly may annoy the host.

##### 'nz_regroupfilesbyyear.py'
The largest data collections 'GrpOrgAllReturns' and 'vOfficerOrganisations' are too big to download in a single request and so have to be downloaded in separate chunks. This file converts the data back into a sensible format based on years. This calls 'nz_rowfixer.py' to attempt to fix broken rows.

##### 'nz_checkintegrity.py'
This script checks for errors caused by unsanitised double quotes combining with commas in strings which causes the strings to break across multiple columns. This is checked by comparing the length of each column to the, known correct, header row. If the option 'mark' is selected any error rows will be put in a separate file called '[filename]_errors_integrity.csv'. If 'fix' is selected the script will call 'nz_rowfixer.py' to try to repair the errors. Remaining errors after this process will be written to an error file.

##### 'nz_codeareas.py'
This file converts a list of strings for each charity describing where they operate, in to separate columns which have a numerical marker indicating whether the area is local, national, or international.

##### 'nz_codederegistration.py'
This file uses regex to create 'nz_orgs_deregreasons_integrity.csv' which contains formatted tuples containing the reasons organisations were deregistered.

##### Function: 'nz_rowfixer.py'
This function is called by 'nz_regroupfilesbyyear.py' and 'nz_checkintegrity.py' and attempts to fix rows which are broken by double quotes and commas interacting. This is necessary because the download method does not allow escaping of these characters. The function works by searching for a cell which starts with white space and ends with a double quote (a characteristic of most but not all errors) and then joins it to the cell to the left. It then checks if the row is the correct length - if it is it is presumed fixed - if not it joins another cell from the left and performs a final check. The file returns the modified row if it is fixed and the original if it couldn't fit it.

Fixed stats: 77% in nz_checkintegrity.py (51 down to 12), 96% in GrpOrgAllReturns (24 down to 1)m and 70% for vOfficerOrganisations 18030 to 5487.

This method is complicated and inelegant but works for most errors. It may be possible to reach 100% by joining a variable number of cells depending on the length target, but this would be more susceptible to false positives.

The errors are difficult to fix because they are not consistent. All errors have a double quote at the end of the data in the last split column (the rightmost column). For example col1: 'This is an' col2: ' example"'. Most errors have a white space character at the start of the rightmost column, as shown in the example - but some do not. Most errors have a double quote somewhere in the leftmost column but this moves around and not all do - for example col1 'This is" an'. Some errors stretch across more than 2 columns.

--





Use this markdown document to record any notes referring to issues associated with the data collection exercise for this country.
For example, the file format of the Annual Information Statement changes over time: see [https://data.gov.au/search?organisation=Australian%20Charities%20and%20Not-for-profits%20Commission](https://data.gov.au/search?organisation=Australian%20Charities%20and%20Not-for-profits%20Commission)

That is just an example of what you might record. As Prof. Gayle likes to say, nobody likes to write documentation but nobody ever regrets writing too many comments/notes!

You might also record whether and where we can find information on dissolution/mission; we will do this more systematically in the data cleaning phase but it could be worth noting anything obvious at this stage. For example this charity has a note on its webpage saying it had its status revoked: [https://www.acnc.gov.au/charity/fd33413e3f2a3d7c5046ede6ce8061ca](https://www.acnc.gov.au/charity/fd33413e3f2a3d7c5046ede6ce8061ca)
