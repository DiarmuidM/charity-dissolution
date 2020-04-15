# Mission Accomplished? A Cross-national Examination of Charity Dissolution

## Data Collection [April - June 2019]

### England & Wales

#### Notes
Charity commission data download seems to contain most of the data including removal in the follow data sets;
'extract_registration' - remdate, remcode
'extract_remove_ref' - code, text
'extract_charity' - orgtype (RM removed)
These are all in .\ew_download\Mar2019\data_extracted
The documentation of this data is at - http://data.charitycommission.gov.uk/data-definition.aspx

Doesn't appear to have anything on mission beyond breakdown of income. This is a set of decomposed tables from an SQL database linked by primary and foreign keys - though these aren't identified in the data we could probably link them back up if needed.

Not sure what cc_SIR_20190410.zip is. cc_TableBuild_20190410.zip appears to be a copy of the data in sql format.

Grabbing data august 2019
When ew_download.py was run on 18/08/19 the first two runs failed to get any status code back, the third worked with no changes to the code.



--





Use this markdown document to record any notes referring to issues associated with the data collection exercise for this country.
For example, the file format of the Annual Information Statement changes over time: see [https://data.gov.au/search?organisation=Australian%20Charities%20and%20Not-for-profits%20Commission](https://data.gov.au/search?organisation=Australian%20Charities%20and%20Not-for-profits%20Commission)

That is just an example of what you might record. As Prof. Gayle likes to say, nobody likes to write documentation but nobody ever regrets writing too many comments/notes!

You might also record whether and where we can find information on dissolution/mission; we will do this more systematically in the data cleaning phase but it could be worth noting anything obvious at this stage. For example this charity has a note on its webpage saying it had its status revoked: [https://www.acnc.gov.au/charity/fd33413e3f2a3d7c5046ede6ce8061ca](https://www.acnc.gov.au/charity/fd33413e3f2a3d7c5046ede6ce8061ca)