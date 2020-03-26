// File: istr_can_data-cleaning.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 25/04/2018
// Updated: recorded in Github file history
// Repository: [ADD LATER]

******* Canada Charity Data - Data Management *******

/* 
	This do file performs the following tasks:
		- imports various csv and excel datasets downloaded from various sources
		- cleans these datasets
		- merges these datasets
		- saves files in Stata format ready for analysis
		
	The main task is to construct a panel dataset using the ais datasets:
		
	We need the following variables to conduct removal analysis:
		- unique identifier (Register)
		- registration status (Register)
		- the year a charity was removed or latest reporting year (UNSURE)
		- a measure of size (Annual Returns)
		- legal status i.e. company or not (UNSURE)
		- sector (REGISTER)
		- scale of operations i.e. local, national and international ideally, or at least a dummy of overseas or not (UNSURE)
		- age (Register and Annual Returns)
*/

clear
capture log close


/* Define paths */

include "C:\Users\mcdonndz-local\Desktop\github\paper-istr-2018\syntax\project_paths.doi"
di "$path1"
di "$path2"
di "$path3"
di "$path4"
di "$path5"
di "$path6"
di "$path7"
di "$path8"

/* Import raw data data */

import delimited $path2\canada_register.csv, varnames(1) clear	
desc, f
count
notes

drop v13

	rename bnregistrationnumber orgid
	
	// Independent variable operationalisation
		
	codebook designationcode
	encode designationcode, gen(charitytype)
	tab charitytype
	label define chartype_lab 1 "Public Foundation" 2 "Private Foundation" 3 "Charitable Organisation" 
	label values charitytype chartype_lab
	tab charitytype
	
	
	codebook effectivedateofstatus
	gen tempdate = subinstr(effectivedateofstatus, "-", "", .)
	codebook tempdate
	gen statusdate = date(tempdate, "YMD")
	codebook statusdate
	format statusdate %td
	gen statyear = year(statusdate)
	tab statyear
	drop tempdate
	
	
	codebook province country
	tab1 province country
	encode province, gen(area)
	tab area, sort
	tab area, sort nolab // Recode to four categories: top 4 + all others
	recode area 31=1 35=2 4=3 1=4 *=5
	tab area
	label define area_lab 1 "Ontario" 2 "Quebec" 3 "British Columbia" 4 "Alberta" 5 "Other Canadian provinces" // I'm not sure about 3 being correct.
	label values area area_lab
	tab area
	
	
	codebook categorycode // E.g. welfare, religion, education, other
	tab categorycode
	gen sector = categorycode
	tab sector
	recode sector 1/9=1 10/19=2 20/29=3 30/49=4 50/max=5 
	/*
		Collapse to group level distinctions e.g. welfare, religion, education, other.
		
		It's worth looking at more granular measures of this variable in the future.
	*/
	label define sec_lab 1 "Welfare" 2 "Health" 3 "Education" 4 "Religion" 5 "Benefits to the community & other" // Regulators classification
	label values sector sec_lab
	tab categorycode sector
	
	**label variable r4950 "Annual gross expenditure"
	**label variable r4700 "Annual gross income"
	**label variable expenditure "Annual gross expenditure"
	**label variable revenue "Annual gross income"
	**label variable status "Registration status of the charity"
	label variable designationcode "Charity type code i.e. private foundation"
	label variable charitytype "Charity type i.e. private foundation"
	label variable sanction "Indicates whether the charity has been penalized or suspended"
	label variable statusdate "Date the charity's status was applied"
	label variable statyear "Year the charity's status was applied"
	label variable sector "Area of activity i.e. health, religion" 
	**label variable charityage "Age of charity in years"
	/*
		We need to calculate charityage but this may prove difficult as we do not have registration date for de-registered charities
		i.e. effectivedateofstatus is the registration date for registered charities, the revokation date for de-registered charities.
	*/
	
	// Dependent variable operationalisation
	
	tab charitystatus
	encode charitystatus, gen(status)
	
	capture drop dereg
	gen dereg = status
	recode dereg 1=0 *=1
	tab dereg status
	label variable dereg "Organisation no longer registered as a charity"
		
	capture drop depvar
	gen depvar = status
	recode depvar 2=0 1 3 4=1 6=2 5=3
	tab depvar
	label define depvar_label 0 "Registered" 1 "Failed" 2 "Vol Dissolution" 3 "Other Dereg"
	label values depvar depvar_label
	label variable depvar "Indicates whether a charity has been de-registered and for what reason"


sort orgid

sav $path3\canada_register_20180522.dta, replace


// 


// canada_sample_organisations_20180517.dta

use $path3\canada_sample_organisations_20180517.dta, clear
count
duplicates report orgid
sort orgid

sav $path1\canada_sample_organisations_merge_20180522, replace




	// Duplicates
	
	duplicates report orgid
	
	
	// Merge with canada_sample_organisations_20180517.dta to get other organisational information
	
	merge 1:1 orgid using $path1\canada_sample_organisations_merge_20180522, keep(match master)
	tab _merge // 604 records not matching.
	
	


/* Clear working data folder */

pwd
	
local workdir "$path1"
cd `workdir'
	
local datafiles: dir "`workdir'" files "*.dta"

foreach datafile of local datafiles {
	rm `datafile'
}
