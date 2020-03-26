// File: istr_aus_data-cleaning.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 25/04/2018
// Updated: recorded in Github file history
// Repository: [ADD LATER]

******* Australia Charity Data - Data Management *******

/* 
	This do file performs the following tasks:
		- imports various csv and excel datasets downloaded from various sources
		- cleans these datasets
		- merges these datasets
		- saves files in Stata format ready for analysis
		
	The main task is to construct a panel dataset using the ais datasets:
		- ignore group accounts for the moment but see the explanatory notes
		
	We need the following variables to conduct removal analysis:
		- unique identifier (Register, Annual Returns)
		- registration status (Annual Returns)
		- the year a charity was removed or latest reporting year (Register, Annual Returns)
		- a measure of size (Register, Annual Returns)
		- legal status i.e. company or not (NO MEASURE IN EITHER DATASET)
		- sector (Annual Returns)
		- scale of operations i.e. local, national and international ideally, or at least a dummy of overseas or not (Annual Returns)
		- age (Register and Annual Returns)
*/

clear
capture log close


/* Define paths */

include "C:\Users\mcdonndz-local\Desktop\github\paper-istr-2018\syntax\project_paths.doi"


/* 1. Import raw data */

// Charity Register
/*
	List of registered charities, does not include revoked organisations.
*/

import delimited using $path2\aus_charityregister.csv, varnames(1) clear
count
di r(N) " charities in this Register"
desc, f
codebook *, problems // Deal with most of these issues as we go along.
	
	// Duplicate records

	duplicates report
	duplicates report abn
	duplicates list abn // All missing values; drop
	duplicates drop abn, force
	
	duplicates report _id
		/*
		duplicates list _id // All missing values
		duplicates tag _id, gen(dupregnum)
		tab dupregnum
		list if dupregnum>0 // Some have information, some do not; drop for now and revisit in future.
		duplicates drop _id, force
		drop dupregnum
		*/

	// Missing values
	
	mdesc 
	/*
		Lots of missing but for some variables this is a valid value (e.g. charity does not have that charitable purpose).
	*/	
	
	// Variable values
	
	codebook *, compact
	
	codebook abn
	rename abn charityid

	
	codebook operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic
	tab1 operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic
	foreach var in operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic {
		replace `var'="1" if `var'=="Y"
		destring `var', replace
		recode `var' .=0
		tab `var'
	}
	mrtab operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic
	
		// Create a count of the number of territories a charity operates in
		
		egen nterritories = rowtotal(operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic)
		list operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic nterritories in 1/50, clean noobs
		sum nterritories, detail
		histogram nterritories, fraction normal scheme(s1mono)
		/*
			Vast majority (~80%) operate in one territory. Could be an interesting analysis of number of territories vs number of countries.
		*/
	
	
	codebook charity_size
	tab charity_size // Need to combine categories; first encode:
	encode charity_size, gen(charitysize)
	tab charity_size charitysize, nolab
	recode charitysize 1 2 7=1 3 4 8=2 5 6 9=3 // large, medium and small categories
	label define charitysize_lab 1 "Large" 2 "Medium" 3 "Small"
	label values charitysize charitysize_lab
	tab charitysize
	drop charity_size
	
	
	codebook financial_year_end
	tab financial_year_end // Captures day and month (in that order)
	gen fye_len = strlen(financial_year_end)
	tab fye_len
	/*
		Count number of characters before "/".
		Turn 3 and 4 character strings into 5 by adding a "/".
	*/
	
	**replace financial_year_end = subinstr(financial_year_end, "/", "", .)
	**tab financial_year_end
	
	
	codebook date_organisation_established
	list date_organisation_established if date_organisation_established!="", clean noobs
	gen estd_len = strlen(date_organisation_established)
	tab estd_len // All the same lenght; means I can extract the year by counting characters.
	gen estyear = substr(date_organisation_established, 7, .) if date_organisation_established!=""	
	tab estyear
	destring estyear, replace
	
	
	codebook operating_countries country
	tab country
	replace country="AUSTRALIA" if country=="Australia"
	rename country str_country
	encode str_country, gen(country)
	tab str_country country, nolab
	recode country 1=. 2=1 3/max=0 // Almost all charities are registered in Australia
	label define country_lab 1 "Australia" 0 "Other"
	label values country country_lab
	tab country
	drop str_country
	
	tab operating_countries, sort miss // Lots of missing values.
	** convert to upper
	**split operating_countries, p(",")
	**tab1 operating_countries*
	/*
		This is tricky: I need a list of country codes in order to be able to count.
		I think this might be too cumbersome, however. Speak to Alasdair about another solution - see NZ python script.
	*/

	
	// Leading, trailing and embedded blanks
	/*
	foreach var in Name Status Alias PrincipalAddress GoverningForm CRONumber CountryEstablished CharitablePurpose CharitableObjects {
		replace `var' = strtrim(`var')
		replace `var' = subinstr(`var', " ", "", .)
	}
	*/	
	
	/* 	Sort data and keep relevant variables for removal analysis */
	
	sort charityid
	keep charityid estyear charitysize
	
save $path3\aus_charityregister.dta, replace	















// Annual Returns 2016

import delimited using $path2\20180207_DataDotGov_AIS16.csv, varnames(1) clear
count
di r(N) " annual returns in 2016"
desc, f
*codebook *, problems // Deal with most of these issues as we go along.
	
	/*
		Try and construct an `areaop` variable using the following definition:
			- Local = one territory
			- National = > one territory
			- International = operateoverseas==1 & no territory
	*/

	keep ïabn registrationstatus charitysize mainactivity operatesoverseas totalgrossincome aisduedate aissubmissiondate
	
	codebook ïabn // Looks like unique id for a charity
	list ïabn in 1/100, clean
	rename ïabn charityid
	duplicates report charityid
	duplicates tag charityid, gen(dupcharid)
	/*
		Deal with duplicates at a later stage; might just have to drop, but see Alasdair's NZ code for dealing with similar issue.
	*/
	
	
	codebook registrationstatus
	tab registrationstatus // No idea what 'A' is; set to missing after I encode
	encode registrationstatus, gen(charitystatus)
	numlabel charitystatus, add
	tab charitystatus
	recode charitystatus 1=. 2=1 3=2 4=3
	label define charstat_lab 1 "Active" 2 "Revoked" 3 "Voluntarily Revoked"
	label values charitystatus charstat_lab
	tab charitystatus
	drop registrationstatus
	
	
	codebook charitysize
	tab charitysize
	encode charitysize, gen(charsize)
	tab charitysize charsize, nolab
	numlabel charsize, add
	tab charsize
	recode charsize 2 4=2 3 5=3 // large, medium and small categories
	label define charsize_lab 1 "Large" 2 "Medium" 3 "Small"
	label values charsize charsize_lab
	tab charsize
	drop charitysize
	
	
	codebook mainactivity
	tab mainactivity // 25 sectors; need to reduce these to a harmonised number of categories with other countries.
	rename mainactivity str_mainactivity
	encode str_mainactivity, gen(mainactivity)
	numlabel mainactivity, add
	
	
	codebook operatesoverseas
	tab operatesoverseas
	encode operatesoverseas, gen(international)
	tab international, nolab
	recode international 1=0 2=1
	tab international
	label define int_lab 0 "No" 1 "Yes"
	label values international int_lab
	tab international
	
	
	codebook totalgrossincome
	sum totalgrossincome, detail
	count if totalgrossincome < 0
		di "The number of observations with total gross income < $0 is " r(N)
		drop if totalgrossincome < 0
		/*
			It might be plausible to convert the sign; read the 2016 state of the sector report for guidance.
		*/
	rename totalgrossincome income
	histogram income, normal fraction
		
		// Create a log version of income
		
		gen ln_income = ln(income) if income > 0 & income!=.
		
	
	codebook aisduedate // Extract year from string
	gen aisduedate_strlen = strlen(aisduedate) // Mainly 10 but some 9:
		list aisduedate if aisduedate_strlen==9
		replace aisduedate = "0" + aisduedate if aisduedate_strlen==9
	
	tab aisduedate_strlen
	gen aisyear_due = substr(aisduedate, 7, .)
	tab aisyear_due
	
	
	// What is the coverage of these annual returns in terms of years?
	
	codebook aissubmissiondate
		gen aissubmissiondate_strlen = strlen(aissubmissiondate) 
		tab aissubmissiondate_strlen // Mainly 10 but some 9:
		list aissubmissiondate if aissubmissiondate_strlen==9
		list aissubmissiondate if aissubmissiondate_strlen==4 // NULL
		replace aissubmissiondate = "0" + aissubmissiondate if aissubmissiondate_strlen==9
	
	tab aissubmissiondate_strlen
	gen aisyear_sub = substr(aissubmissiondate, 7, .)
	tab aisyear_sub // Covers 2016-2017 (with a small number of 2018)
	
sort charityid
*drop if dupcharid==1 // Only need one observation for matching with the Register.
drop str_mainactivity operatesoverseas aisduedate_strlen aissubmissiondate_strlen // Drop superfluous variables

gen aryear = 2016

save $path1\aus_annret_2016.dta, replace	



// Annual Returns 2015

import delimited using $path2\20180207_DataDotGov_AIS15.csv, varnames(1) clear
count
di r(N) " annual returns in 2015"
desc, f
*codebook *, problems // Deal with most of these issues as we go along.
	
	/*
		Try and construct an `areaop` variable using the following definition:
			- Local = one territory
			- National = > one territory
			- International = operateoverseas==1 & no territory
	*/

	keep ïabn registration_status charity_size main_activity operates_overseas total_gross_income ais_due_date date_ais_received
	
	codebook ïabn // Looks like unique id for a charity
	list ïabn in 1/100, clean
	rename ïabn charityid
	duplicates report charityid
	*duplicates tag charityid, gen(dupcharid)
	/*
		No duplicates.
	*/
	
	
	codebook registration_status
	tab registration_status // No idea what 'A' is; set to missing after I encode
	encode registration_status, gen(charitystatus)
	numlabel charitystatus, add
	tab charitystatus
	recode charitystatus 1=. 2=1 3=2 4=3
	label define charstat_lab 1 "Active" 2 "Revoked" 3 "Voluntarily Revoked"
	label values charitystatus charstat_lab
	tab charitystatus
	drop registration_status
	
	
	codebook charity_size
	tab charity_size
	encode charity_size, gen(charsize)
	tab charity_size charsize, nolab
	numlabel charsize, add
	tab charsize
	recode charsize 1 5=1 2 6=2 3 4 7=3 // large, medium and small categories
	label define charsize_lab 1 "Large" 2 "Medium" 3 "Small"
	label values charsize charsize_lab
	tab charsize
	drop charity_size
	
	
	codebook main_activity
	tab main_activity // 27 sectors; need to reduce these to a harmonised number of categories with other countries.
	rename main_activity str_mainactivity
	encode str_mainactivity, gen(mainactivity)
	numlabel mainactivity, add
	
	
	codebook operates_overseas
	tab operates_overseas
	encode operates_overseas, gen(international)
	tab international, nolab
	recode international 1=0 2=1
	tab international
	label define int_lab 0 "No" 1 "Yes"
	label values international int_lab
	tab international
	
	
	codebook total_gross_income
	sum total_gross_income, detail
	count if total_gross_income < 0
		di "The number of observations with total gross income < $0 is " r(N)
		drop if total_gross_income < 0
		/*
			It might be plausible to convert the sign; read the 2016 state of the sector report for guidance.
		*/
	rename total_gross_income income
	histogram income, normal fraction
		
		// Create a log version of income
		
		gen ln_income = ln(income) if income > 0 & income!=.
		
	
	codebook ais_due_date // Extract year from string
	gen aisduedate_strlen = strlen(ais_due_date)
	tab aisduedate_strlen // The correct length is 22
		list ais_due_date if aisduedate_strlen==20
		replace ais_due_date = "00" + ais_due_date if aisduedate_strlen==20
		
		list ais_due_date if aisduedate_strlen==21
		replace ais_due_date = "0" + ais_due_date if aisduedate_strlen==21
	
	list ais_due_date in 1/100
	gen aisyear_due = substr(ais_due_date, 7, 4)
	tab aisyear_due
	rename ais_due_date aisduedate
	
	
	// What is the coverage of these annual returns in terms of years?
	
	codebook date_ais_received
	gen aissubmissiondate_strlen = strlen(date_ais_received) 
	tab aissubmissiondate_strlen
	gen aisyear_sub = substr(date_ais_received, 7, .)
	tab aisyear_sub
	rename date_ais_received aissubmissiondate
	
	
sort charityid
*drop if dupcharid==1 // Only need one observation for matching with the Register.
drop str_mainactivity operates_overseas aisduedate_strlen aissubmissiondate_strlen // Drop superfluous variables

gen aryear = 2015

save $path1\aus_annret_2015.dta, replace
	
	
	
// Annual Returns 2014

import delimited using $path2\20180207_DataDotGov_AIS14.csv, varnames(1) clear
count
di r(N) " annual returns in 2014"
desc, f
*codebook *, problems // Deal with most of these issues as we go along.
	
	/*
		Try and construct an `areaop` variable using the following definition:
			- Local = one territory
			- National = > one territory
			- International = operateoverseas==1 & no territory
	*/

	keep ïabn registration_status charity_size main_activity operates_overseas total_gross_income ais_due_date date_ais_received
	
	codebook ïabn // Looks like unique id for a charity
	list ïabn in 1/100, clean
	rename ïabn charityid
	duplicates report charityid
	*duplicates tag charityid, gen(dupcharid)
	/*
		No duplicates.
	*/
	
	
	codebook registration_status
	tab registration_status // No idea what 'A' is; set to missing after I encode
	encode registration_status, gen(charitystatus)
	numlabel charitystatus, add
	tab charitystatus
	recode charitystatus 1=. 2=1 3=2 4=3
	label define charstat_lab 1 "Active" 2 "Revoked" 3 "Voluntarily Revoked"
	label values charitystatus charstat_lab
	tab charitystatus
	drop registration_status
	
	
	codebook charity_size
	tab charity_size
	encode charity_size, gen(charsize)
	tab charity_size charsize, nolab
	numlabel charsize, add
	tab charsize
	recode charsize 1 6=1 2 3 7=2 4 5 8=3 // large, medium and small categories
	label define charsize_lab 1 "Large" 2 "Medium" 3 "Small"
	label values charsize charsize_lab
	tab charsize
	drop charity_size
	
	
	codebook main_activity
	tab main_activity // 30 sectors; need to reduce these to a harmonised number of categories with other countries.
	rename main_activity str_mainactivity
	encode str_mainactivity, gen(mainactivity)
	numlabel mainactivity, add
	
	
	codebook operates_overseas
	tab operates_overseas
	encode operates_overseas, gen(international)
	tab international, nolab
	recode international 1=0 2=1
	tab international
	label define int_lab 0 "No" 1 "Yes"
	label values international int_lab
	tab international
	
	
	codebook total_gross_income
	sum total_gross_income, detail
	count if total_gross_income < 0
		di "The number of observations with total gross income < $0 is " r(N)
		drop if total_gross_income < 0
		/*
			It might be plausible to convert the sign; read the 2016 state of the sector report for guidance.
		*/
	rename total_gross_income income
	histogram income, normal fraction
		
		// Create a log version of income
		
		gen ln_income = ln(income) if income > 0 & income!=.
		
	
	codebook ais_due_date // Extract year from string
	gen aisduedate_strlen = strlen(ais_due_date)
	tab aisduedate_strlen
	gen aisyear_due = substr(ais_due_date, 7, 4)
	tab aisyear_due
	rename ais_due_date aisduedate
	
	
	// What is the coverage of these annual returns in terms of years?
	
	codebook date_ais_received
	gen aissubmissiondate_strlen = strlen(date_ais_received) 
	tab aissubmissiondate_strlen
	gen aisyear_sub = substr(date_ais_received, 7, .)
	tab aisyear_sub
	rename date_ais_received aissubmissiondate
	
	
sort charityid
*drop if dupcharid==1 // Only need one observation for matching with the Register.
drop str_mainactivity operates_overseas aisduedate_strlen aissubmissiondate_strlen // Drop superfluous variables
	
gen aryear = 2014

save $path1\aus_annret_2014.dta, replace


// Annual Returns 2013
/*
import delimited using $path2\20180207_DataDotGov_AIS13.csv, varnames(1) clear
count
di r(N) " annual returns in 2013"
desc, f
*codebook *, problems // Deal with most of these issues as we go along.
	
	/*
		Try and construct an `areaop` variable using the following definition:
			- Local = one territory
			- National = > one territory
			- International = operateoverseas==1 & no territory
			
		I don't think 2013 annual returns are much good:
			- no registration status or operates overseas
	*/

	keep ïabn registration_status charity_size main_activity operates_overseas total_gross_income ais_due_date date_ais_received
	
	codebook ïabn // Looks like unique id for a charity
	list ïabn in 1/100, clean
	rename ïabn charityid
	duplicates report charityid
	*duplicates tag charityid, gen(dupcharid)
	/*
		No duplicates.
	*/
	
	
	codebook registration_status
	tab registration_status // No idea what 'A' is; set to missing after I encode
	encode registration_status, gen(charitystatus)
	numlabel charitystatus, add
	tab charitystatus
	recode charitystatus 1=. 2=1 3=2 4=3
	label define charstat_lab 1 "Active" 2 "Revoked" 3 "Voluntarily Revoked"
	label values charitystatus charstat_lab
	tab charitystatus
	drop registration_status
	
	
	codebook charity_size
	tab charity_size
	encode charity_size, gen(charsize)
	tab charity_size charsize, nolab
	numlabel charsize, add
	tab charsize
	recode charsize 1 6=1 2 3 7=2 4 5 8=3 // large, medium and small categories
	label define charsize_lab 1 "Large" 2 "Medium" 3 "Small"
	label values charsize charsize_lab
	tab charsize
	drop charity_size
	
	
	codebook main_activity
	tab main_activity // 30 sectors; need to reduce these to a harmonised number of categories with other countries.
	rename main_activity str_mainactivity
	encode str_mainactivity, gen(mainactivity)
	numlabel mainactivity, add
	
	
	codebook operates_overseas
	tab operates_overseas
	encode operates_overseas, gen(international)
	tab international, nolab
	recode international 1=0 2=1
	tab international
	label define int_lab 0 "No" 1 "Yes"
	label values international int_lab
	tab international
	
	
	codebook total_gross_income
	sum total_gross_income, detail
	count if total_gross_income < 0
		di "The number of observations with total gross income < $0 is " r(N)
		drop if total_gross_income < 0
		/*
			It might be plausible to convert the sign; read the 2016 state of the sector report for guidance.
		*/
	rename total_gross_income income
	histogram income, normal fraction
		
		// Create a log version of income
		
		gen ln_income = ln(income) if income > 0 & income!=.
		
	
	codebook ais_due_date // Extract year from string
	gen aisduedate_strlen = strlen(ais_due_date)
	tab aisduedate_strlen
	gen aisyear_due = substr(ais_due_date, 7, 4)
	tab aisyear_due
	
	
	// What is the coverage of these annual returns in terms of years?
	
	codebook date_ais_received
	gen aissubmissiondate_strlen = strlen(date_ais_received) 
	tab aissubmissiondate_strlen
	gen aisyear_sub = substr(date_ais_received, 7, .)
	tab aisyear_sub
	
	
sort charityid
*drop if dupcharid==1 // Only need one observation for matching with the Register.
drop str_mainactivity operates_overseas aisduedate_strlen aissubmissiondate_strlen // Drop superfluous variables

gen aryear = 2013

save $path1\aus_annret_2013.dta, replace		
*/	


/* Append annual returns together */

use $path1\aus_annret_2014.dta, clear

append using $path1\aus_annret_2015.dta, force
append using $path1\aus_annret_2016.dta, force

count
desc, f

	/*
		There are far too many categories of mainactivity; create a derived variable with six categories:
			- top five most common, and collapse the rest into 'other'.
	*/
	
	capture drop sector
	gen sector = mainactivity
	tab sector, sort
	recode sector 24=1 22=2 27=3 21=4 20=5 .=. *=6
	tab1 sector mainactivity, sort
	label define sector_lab 1 "Philathropic Promotion" 2 "Other Health Service Delivery" 3 "Religious Activities" 4 "Other Education" 5 "Other" 6 "Any Other Activity"
	label values sector sector_lab
	/*
		This is not very informative as a method of collapsing the categories.
	*/

	/* Look at when a charity was first appeared as revoked */
	
	codebook charityid // 51,914 unique charities
	tab charitystatus aryear // Shows the number of charities appearing as revoked in a single year
	duplicates report charityid charitystatus if charitystatus!=1
	duplicates list charityid charitystatus if charitystatus!=1
	duplicates tag charityid charitystatus if charitystatus!=1, gen(dupcharstat)
	tab dupcharstat
	
	list charityid aryear charitystatus if dupcharstat!=0 & charitystatus!=1, clean
	
	// Variable capturing most recent appearance in the dataset
	
	bysort charityid: egen aryear_latest = max(aryear)
	tab aryear_latest
	
	// Set in panel format
	
	**xtset charityid aryear
	

sort charityid aryear

label variable charityid "Unique id of charity"
label variable aryear "Year financial information refers to"
label variable aisyear_due "Year annual return was due"
label variable aisyear_sub "Year annual return was submitted"

save $path3\aus_annret_2014-16.dta, replace


*********************************************************************************************************************


*********************************************************************************************************************




/* Clear working data folder */

pwd
	
local workdir "$path1"
cd `workdir'
	
local datafiles: dir "`workdir'" files "*.dta"

foreach datafile of local datafiles {
	rm `datafile'
}
