# Mission Accomplished? A Cross-national Examination of Charity Dissolution

## Data Collection [April - June 2019]

## Canada

### Notes
The regulator's site seems to go down between 02:00 a.m. and 06:00 a.m. EST every day for maintinence. Any long term scraper is going to have to deal with this. 'can_scrape_charlinks.py'takes under 6 hours so should be fine if started early enough.

Some charities (https://apps.cra-arc.gc.ca/ebci/hacc/srch/pub/dsplyRprtngPrd?q.stts=0007&selectedCharityId=124322340&selectedCharityBn=734970320RR1&dsrdPg=1) don't seem to have full pages.

Links must have the RR number as 000[number] so Bn=734970320RR1 must be Bn=734970320RR0001

The website won't seem to let Python access the financial links (http://www.cra-arc.gc.ca/ebci/hacc/srch/pub/t3010/v23/t3010Schdl6_dsplyovrvw) even though they can be accessed from the browser - may be to do with cookies.

### Scripts
##### ''

--





Use this markdown document to record any notes referring to issues associated with the data collection exercise for this country.
For example, the file format of the Annual Information Statement changes over time: see [https://data.gov.au/search?organisation=Australian%20Charities%20and%20Not-for-profits%20Commission](https://data.gov.au/search?organisation=Australian%20Charities%20and%20Not-for-profits%20Commission)

That is just an example of what you might record. As Prof. Gayle likes to say, nobody likes to write documentation but nobody ever regrets writing too many comments/notes!

You might also record whether and where we can find information on dissolution/mission; we will do this more systematically in the data cleaning phase but it could be worth noting anything obvious at this stage. For example this charity has a note on its webpage saying it had its status revoked: [https://www.acnc.gov.au/charity/fd33413e3f2a3d7c5046ede6ce8061ca](https://www.acnc.gov.au/charity/fd33413e3f2a3d7c5046ede6ce8061ca)
