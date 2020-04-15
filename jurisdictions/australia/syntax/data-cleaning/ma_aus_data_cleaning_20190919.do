// File: ma_aus_data_cleaning_20190919.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 19/09/2019

******* Australia data cleaning *******

/* This DO file marshals the raw charity charity to produce a data set suitable for analysis:
	- imports raw data in csv format
	- cleans these datasets
	- links these datasets
	- saves these datasets in Stata and CSV formats
	
	See 'acncregisterdatanotes.rtf' for a description the fields.
	
	To Do:
	- Link area level data for Aus
	- Link country codes to data set [DONE]
		o used list from https://gist.github.com/tadast/8827699
	
*/


/** 0. Define paths **/

global dfiles "C:\Users\mcdonndz-local\Dropbox" // location of data files
global rfiles "C:\Users\mcdonndz-local\Desktop" // location of syntax and outputs
global diarmuid "C:\Users\mcdonndz-local\Desktop\github\mission_accomp\syntax" // location of "project_paths.doi"

include "$diarmuid\project_paths.doi"


/** 1. Import data **/


** Country Codes **

import delimited using $path2\aus\iso_country_codes_20190919.csv, varnames(1) clear
count
desc, f

	rename ïcountry country
	keep country alpha3code
	
sav $path3\aus\iso_country_codes_20190919.dta, replace


** Charity Web Ids **

import delimited using $path2\aus\auscharities_web-ids_2019-09-19.csv, varnames(1) clear
count
desc, f

	duplicates report *
	duplicates list *
	duplicates drop *, force
	
		duplicates report charitywebid
		duplicates list charitywebid // null and missing values
		duplicates drop charitywebid, force
		
	
	// Keep relevant cases

	drop if note=="Likely an invalid ABN"
	
	
	// Check variable values
	
	rename charitywebid cwid
	label variable cwid "ACNC website id of charity"
	sort cwid
	
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	
		capture tab ccnum if missing(real(ccnum))
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace


	codebook charityname
	l charityname in 1/50
	rename charityname name
	label variable name "Legal name of charity"

	
compress
datasignature set
sav $path3\aus\aus_webids_20190919.dta, replace	


** Revocations **

import delimited using $path2\aus\auscharities_rev_2019-09-21.csv, varnames(1) clear
count
desc, f

	// Keep relevant cases
	
	duplicates report *
	duplicates list * // lots of duplicates due to double-listing on ACNC website; drop
	duplicates drop *, force
	
		duplicates report charitywebid status
		duplicates list charitywebid status // seemingly valid duplicates; tag
		duplicates tag charitywebid status, gen(dupcharstat)
		
	drop if status=="NULL" | status=="NULL - GROUP" // no revocation status on webpage
	
	
	// Check variable values
	
	rename charitywebid cwid
	label variable cwid "ACNC website id of charity"
	
	
	codebook effectivedate
	l effectivedate in 1/100
	gen statusd = date(effectivedate, "DMY")
	format statusd %td
	drop effectivedate
	label variable statusd "Date of status change"

		gen statusy = year(statusd)
		tab statusy
		label variable statusy "Year of status change"
		
	
	sort cwid statusy // sort by id and year
	bys cwid: gen status_id = _n // id of status - registration is first event

	
	codebook status
	tab status
	rename status str_status
	encode str_status, gen(orgdiss)
	/*
		Until I hear from ACNC or NC, collapse the categories as follows:
			0 - Registered
			1 - Failed to file
			2 - Voluntary removal
			3 - Wound up
			4 - Failed to file (other)
			
		With the exception of category 4, these are harmonised to NZ dissolution.	
	*/
	recode orgdiss 1=0 4=1 7 8 10=2 9=3 2 3 5 6=4
	label define orgdiss_lab 0 "Registered" 1 "Failed to file" 2 "Voluntary removal" 3 "Wound up" 4 "Failed to file (other)"
	label values orgdiss orgdiss_lab
	label variable orgdiss "Dissolution status of charity"

	
	// Summary statistics
		
	bys cwid: gen status_total = _N // total number of statuses
	bys cwid: gen status_gap = statusy - statusy[_n-1]
	/*
		Calculate time between statuses.
	*/
	sum status_total status_gap
	tabstat status_gap , s(mean p50 n) by(status_id)
	table status_id orgdiss, c(mean status_gap n status_gap)
	/*
		Three years between registration and first status update, 0 years between first status update and next
		status update.
	*/
	
	drop if orgdiss==0 // we don't need registration statuses, as we have this variable in the Charity Register; drop

	/*
	// Reshape wide
	
	drop status_total dupcharstat statusd statusy
	reshape wide status, i(cwid) j(status_id)
	duplicates report cwid
	/*
		No effective date information.
	*/

	sav $path1\aus_revocation_wide_20190921.dta, replace
	*/
	
	// Examine duplicates once more
	
	duplicates report cwid orgdiss statusy
	duplicates list cwid orgdiss statusy
	duplicates drop cwid orgdiss statusy, force
	
	duplicates report cwid orgdiss
	duplicates list cwid orgdiss
	duplicates drop cwid orgdiss, force
	
	duplicates report cwid
	duplicates list cwid // valid duplicates - charities that experienced more than one type of dissolution?
	duplicates drop cwid, force
	/*
		Need to return to this issue, as many duplicates will be valid.
	*/
	
	
compress
datasignature set	
sav $path3\aus\aus_revocation_20190921.dta, replace
		

** Charity Register **

import excel $path2\aus\datadotgov_main_2019-09-19.xlsx, first clear
desc, f
count

	// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report ABN
		duplicates list ABN // look to be caused by data entry issues; tag and drop
		duplicates tag ABN, gen(dupabn)
		l if dupabn > 0
		duplicates drop ABN, force
	
	
	// Rename variables to lower case
	
	rename *, lower
	
	
	// Keep relevant variables
	
	drop country
	
	
	// Keep relevant cases
	
	drop if abn==""
	
	
	// Missing data
	
	mdesc

	
	// Check variable values
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	
		tab ccnum if missing(real(ccnum))
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace
	
	
	** Areas of operation
	
	codebook operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic
	tab1 operates_in_act operates_in_wa operates_in_sa operates_in_qld operates_in_nt operates_in_tas operates_in_nsw operates_in_vic
	foreach var in act wa sa qld nt tas nsw vic {
		rename operates_in_`var' areaop_`var'
		replace areaop_`var'="1" if areaop_`var'=="Y"
		destring areaop_`var', replace
		recode areaop_`var' .=0
		tab areaop_`var'
	}
	mrtab areaop_*
	
		// Create a count of the number of territories a charity operates in
		
		egen areaop_total = rowtotal(areaop_act areaop_wa areaop_sa areaop_qld areaop_nt areaop_tas areaop_nsw areaop_vic)
		list areaop_act areaop_wa areaop_sa areaop_qld areaop_nt areaop_tas areaop_nsw areaop_vic areaop_total in 1/50, clean noobs
		sum areaop_total, detail
		histogram areaop_total, fraction normal scheme(s1mono)
		label variable areaop_total "Number of territories a charity operates in"
		/*
			Vast majority (~80%) operate in one territory.
		*/

	
	codebook charity_legal_name
	l charity_legal_name in 1/50
	rename charity_legal_name name
	label variable name "Legal name of charity"
	
	
	codebook other_organisation_names
	rename other_organisation_names name_oth
	label variable name_oth "Other name(s) of charity e.g. trading name"
	
	
	codebook charity_size // measure of reporting thresholds
	tab charity_size // Need to combine categories; first encode:
	encode charity_size, gen(rtype)
	tab charity_size rtype, nolab
	label define rtype_lab 1 "Large (>= 1m)" 2 "Medium (250k - 1m)" 3 "Small (< 250k)"
	label values rtype rtype_lab
	tab rtype
	drop charity_size
	label variable rtype "Reporting threshold for charity"
	
	
	** Registration and establishment dates 
	
	codebook registration_date
	gen regd = date(registration_date, "DMY")
	format regd %td
	drop registration_date
	label variable regd "Date charity was registered with Regulator"
	notes regd : For charities that were registered for tax concession prior to the establishment of the ACNC, ///
		this date will automatically be 3 December 2012 (the date the ACNC commenced).

		gen regy = year(regd)
		tab regy
		label variable regy "Year charity was registered with Regulator"

	
	codebook date_organisation_established
	gen estd = date(date_organisation_established, "DMY")
	format estd %td
	drop date_organisation_established
	label variable estd "Date charity was established as an organisation"
	notes estd : Some organisations run as not-for-profits for years before deciding to register as charities.

		gen esty = year(estd)
		tab esty
		label variable esty "Year charity was established as an organisation"


	** Number of trustees
	
	codebook number_of_responsible_persons
	rename number_of_responsible_persons orgct
	recode orgct 0=.
	notes orgct : A zero in this field indicates that a charity has not supplied this information.
	label variable orgct "The number of board members or committee members the charity has"
	
	
	** Organisation type
	
	codebook pbi hpc
	foreach var in pbi hpc {
		replace `var'="1" if `var'=="Y"
		destring `var', replace
		recode `var' .=0
		tab `var'
	}
	label variable pbi "Public Benefit Institution"
	label variable hpc "Health Promotion Charity"
	notes pbi : A public benevolent institution (PBI) is a type of charitable institution whose main purpose ///
		is to relieve poverty, sickness, suffering or disability. 
	notes hpc : A health promotion charity (HPC) is a charitable institution whose principal activity is to ///
		promote the prevention or control of diseases in people.
		
	
	** Address
	
	codebook address* town* state postcode
	drop address_type // constant
	
	tab postcode if missing(real(postcode))
	replace postcode = "" if missing(real(postcode))
	destring postcode, replace // postcode should be a 4-digit number.
	
	tab state, miss
	rename state str_state
	replace str_state = ltrim(str_state)
	replace str_state = rtrim(str_state)
	gen state = .
	replace state = 1 if str_state=="NEW SOUTH WALES" | str_state=="NSW" | str_state=="New South Wales"
	replace state = 2 if str_state=="ACT" | str_state=="Australian Capital Territory"
	replace state = 3 if str_state=="NT" | str_state=="Northern Territory"
	replace state = 4 if str_state=="QLD" | str_state=="Qld" | str_state=="Queensland"
	replace state = 5 if str_state=="SA" | str_state=="South Australia"
	replace state = 6 if str_state=="TAS" | str_state=="Tas" | str_state=="Tasmania"
	replace state = 7 if str_state=="VIC" | str_state=="Vic" | str_state=="Victoria"
	replace state = 8 if str_state=="WA" | str_state=="WESTERN AUSTRALIA" | str_state=="Western Australia"
	tab state str_state
	drop str_state
	label define state_lab 1 "New South Wales" 2 "Australian Capital Territory" 3 "Northern Territory" 4 "Queensland" ///
		5 "South Australia" 6 "Tasmania" 7 "Victoria" 8 "Western Australia"
	label values state state_lab
	
	
	** Charitable purposes
	
	codebook preventing_or_relieving_sufferin-aboriginal_or_tsi
	foreach var of varlist preventing_or_relieving_sufferin-aboriginal_or_tsi {
		replace `var'="1" if `var'=="Y"
		destring `var', replace
		recode `var' .=0
		tab `var'
	}	
	notes : Many charities will not yet have updated their details to reflect their charitable purpose (also known as sub-type) under ///
		the 2014 Act.
	
	egen cp_total = rowtotal(preventing_or_relieving_sufferin-aboriginal_or_tsi)
	sum cp_total, detail
	label variable cp_total "Number of charitable purposes pursued" 
	
	
	** Beneficiaries
	
	codebook aged_persons-youth
	foreach var of varlist aged_persons-youth {
		capture replace `var'="1" if `var'=="Y"
		capture destring `var', replace
		recode `var' .=0
		tab `var'
	}
	notes : The beneficiary group variables are unlikely to be up-to-date i.e. highly unlikely no charity works for the ///
		benefit of children (as indicated by the data).
	
	egen bg_total = rowtotal(aged_persons-youth)
	sum bg_total, detail
	label variable bg_total "Number of beneficiary groups served" 

	/*
		No charity selected "Children" of "Aged Persons" as a beneficiary group?
	*/

		
	** Operating countries
	
	codebook operating_countries // any countries besides Australia (hence volume of missing values)
	tab operating_countries, sort miss // follows ISO 3166-1 alpha 3 codes
	gen overop = 0
	replace overop = 1 if operating_countries!="" // indicator of whether charity operates overseas
	label variable overop "Operates overseas"
	split operating_countries, p(",")
	tab1 operating_countries*

		// Tidy up values of the variables
		
		local counter = 1
		foreach var of varlist operating_countries1-operating_countries183  {
			gen oc`counter'=subinstr(`var'," ","",.)
			drop `var'
			local counter = `counter' + 1
		}
		
		// Grab list of country codes
		
		preserve 
			use $path3\aus\iso_country_codes_20190919.dta, clear
			rename alpha3code oc
			levelsof oc, local(levels) 
		restore
		
		// Count occurences of country across variables
		
		local counter = 1
		foreach l of local levels {
			gen country`counter' = 0 if operating_countries!=""
			label variable country`counter' "`l'"
			foreach v of varlist oc1-oc183 {
				replace country`counter' = country`counter' + 1 if `v'=="`l'"
			}
			local counter = `counter' + 1
		}
		
		egen oc_total = rowtotal(country1-country243)
		sum oc_total, detail
		sum oc_total if operating_countries!="", detail
		label variable oc_total "Number of overseas countries charity operates in"
		/*
			Is zero a sensible value? I think so i.e. no overseas countries served.
			
			Final task: get country name instead of code for labelling variables.
		*/
	
		drop operating_countries* oc1-oc183 // don't need these variables
		
	
	** Financial year end
	
	codebook financial_year_end
	tab financial_year_end // Captures day and month (in that order)
	gen fye_len = strlen(financial_year_end)
	tab fye_len

	
compress
datasignature set
sav $path3\aus\aus_charreg_20190910.dta, replace


** Annual Returns **

// 2013

import excel $path2\aus\aus_ais_2013.xlsx, clear first
count
desc, f
/*
	2013 annual returns do not contain financial data, hence not very useful.
	
	Therefore keep just a handful of key variables plus an identifier that a charity appeared in this file.
*/
	rename *, lower
	desc, f
	
	
	// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report abn
		duplicates list abn
	
		
	// Keep relevant variables
	
	drop country
	
	
	// Keep relevant cases
	
	drop if abn==""
	
	
	// Missing data
	
	mdesc

	
	// Check variable values
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	/*
		Look for mentions of "superseded" in ccnum.
	*/

		l ccnum charity_name if regex(ccnum, "superseded")
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace
		
	
	codebook charity_name
	l charity_name in 1/50
	rename charity_name name
	label variable name "Legal name of charity"
	
	
	codebook other_organisation_names
	rename other_organisation_names name_oth
	label variable name_oth "Other name(s) of charity e.g. trading name"
	
	
	codebook charity_size // measure of reporting thresholds
	tab charity_size // Need to combine categories; first encode:
	encode charity_size, gen(rtype)
	tab charity_size rtype, nolab
	recode rtype 1 2 7=1 3 4 8=2 5 6 9=3
	label define rtype_lab 1 "Large (>= 1m)" 2 "Medium (250k - 1m)" 3 "Small (< 250k)"
	label values rtype rtype_lab
	tab rtype
	drop charity_size
	label variable rtype "Reporting threshold for charity"
	notes rtype : A charity can apply to report under a different threshold if its income for that year is anomalous ///
		i.e. income and reporting threshold might not match for a given year.

		
	** Registration status
	/*
		Not captured in 2013 annual return file; treat every organisation as registered.
	*/
	
	gen orgstatus = 1
	label define orgstatus_lab 1 "Registered" 2 "Revoked" 3 "Voluntarily Revoked"
	label values orgstatus orgstatus_lab
	tab orgstatus
		
		
	codebook basic_religious
	tab basic_religious
	replace basic_religious="1" if basic_religious=="y"
	replace basic_religious="0" if basic_religious=="n"
	destring basic_religious, replace
	tab basic_religious
	rename basic_religious brc
	label variable brc "Basic Religious Charity"
	notes brc : This subtype is exempt from regulatory requirements e.g. filing financial reports with ACNC.
	
	
	** Financial year start and end dates
	
	codebook financial_year_end
	
	gen fin_year = 2013
			
			
sort ccnum fin_year
compress
datasignature set, reset
sav $path3\aus\aus_ar_2013.dta, replace


// 2014 

import excel $path2\aus\aus_ais_2014.xlsx, clear first
count
desc, f
notes : This dataset provides a record of the 2014 AISs submitted by charities, that is, the ///
	statements submitted for the 2014 reporting period. 

	rename *, lower
	desc, f
	
	
	// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report abn
		duplicates list abn
	
		
	// Keep relevant variables
	
	drop country
	
	
	// Keep relevant cases
	
	drop if abn==""
	
	
	// Missing data
	
	mdesc

	
	// Check variable values
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	/*
		Look for mentions of "superseded" in ccnum.
	*/

		l ccnum charity_name if regex(ccnum, "superseded")
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace
		
	
	codebook charity_name
	l charity_name in 1/50
	rename charity_name name
	label variable name "Legal name of charity"
	
	
	codebook other_organisation_names
	rename other_organisation_names name_oth
	label variable name_oth "Other name(s) of charity e.g. trading name"
	
	
	codebook charity_size // measure of reporting thresholds
	tab charity_size // Need to combine categories; first encode:
	encode charity_size, gen(rtype)
	tab charity_size rtype, nolab
	recode rtype 1 7=1 2/4 8=2 5 6 9=3
	label define rtype_lab 1 "Large (>= 1m)" 2 "Medium (250k - 1m)" 3 "Small (< 250k)"
	label values rtype rtype_lab
	tab rtype
	drop charity_size
	label variable rtype "Reporting threshold for charity"
	notes rtype : A charity can apply to report under a different threshold if its income for that year is anomalous ///
		i.e. income and reporting threshold might not match for a given year.

		
	codebook registration_status
	gen orgstatus = 1 if registration_status=="Registered"
	replace orgstatus = 2 if inlist(registration_status,"Revoked Compliance", "Revoked Double Defaulter", "Revoked RTS", "Revoked Registration")
	replace orgstatus = 3 if regex(registration_status, "Voluntarily")
	label define orgstatus_lab 1 "Registered" 2 "Revoked" 3 "Voluntarily Revoked"
	label values orgstatus orgstatus_lab
	tab orgstatus
	drop registration_status
	notes orgstatus : Some charities that no longer have an active registration might still have needed to ///
		lodge for 2014, or may have had their registration revoked in the time between lodging ///
		and when the dataset was generated.
	/*
		Treat this similarly to 'orgdiss'.
	*/
		
		
	codebook brc
	tab brc
	replace brc="1" if brc=="y"
	replace brc="0" if brc=="n"
	destring brc, replace
	tab brc
	label variable brc "Basic Religious Charity"
	notes brc : This subtype is exempt from regulatory requirements e.g. filing financial reports with ACNC.
	
	
	** Financial year start and end dates
	
	codebook fin_report*
	gen fys = date(fin_report_from, "DMY")
	format fys %td
	drop fin_report_from
	label variable fys "Date financial year began on"
	
	gen fye = date(fin_report_to, "DMY")
	format fys %td
	drop fin_report_to
	label variable fye "Date financial year ends on"
	
	gen fin_year = 2014
	
	
	** Submission and due dates
		
	codebook ais_due_date date_ais_received
	gen aisdue = date(ais_due_date, "DMY")
	format aisdue %td
	drop ais_due_date
	label variable aisdue "Date AIS was due (usually six months after fye)"

	gen aisfil = date(date_ais_received, "DMY")
	format aisfil %td
	drop date_ais_received
	label variable aisfil "Date AIS was filed"

	gen finfil = date(financial_report_date_received, "DMY")
	format finfil %td
	drop financial_report_date_received
	label variable finfil "Date financial report was filed"

	gen overdue = (aisfil > aisdue) // indicator of whether a charity filed late
	label variable overdue "AIS was filed late"
	
	
	** Activities
	
	codebook conducted_activities
	replace conducted_activities="1" if conducted_activities=="y"
	replace conducted_activities="0" if conducted_activities=="n"
	destring conducted_activities, replace
	tab conducted_activities
	rename conducted_activities active
	label variable active "Conducted activities during the year"
	notes active : This field records whether or not a charity conducted any activities in the reporting period.

		
	/*
	codebook main_activity
	tab main_activity 
	/*
		Similar to Rep. of Ireland approach; needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/
	encode mainactivity, gen(mainact)
	tab1 main*
	recode mainact 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainact
	tab mainactivity mainact
	label drop mainact
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainactivity
	*/
	
	codebook animal_protection-other_activity
	foreach var of varlist animal_protection-other_activity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen act_total = rowtotal(animal_protection-other_activity)
	replace act_total = act_total + 1 if main_activity!="" // count main activity also
	sum act_total, detail
	label variable act_total "Number of types of activities engaged in" 
 
		
	** Purposes
	
	codebook will_purposes_change_in_the_next
	tab will_purposes_change_in_the_next
	replace will_purposes_change_in_the_next = "1" if will_purposes_change_in_the_next=="y"
	replace will_purposes_change_in_the_next = "0" if will_purposes_change_in_the_next=="n"
	destring will_purposes_change_in_the_next, replace
	rename will_purposes_change_in_the_next purp_change
	label variable purp_change "Planning changes to charitable purposes in next reporting year"

	
	** Beneficiaries
	/*
	codebook mainbeneficiaries
	tab mainbeneficiaries 
	/*
		Needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/

	encode mainbeneficiaries, gen(mainben)
	tab1 main*
	recode mainben 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainben
	tab mainbeneficiaries mainben
	label drop mainben
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainbeneficiaries
	
	
	codebook animalprotection-otherphilanthropicintermediari otheractivity
	foreach var of varlist animalprotection-otherphilanthropicintermediari otheractivity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen ben_total = rowtotal(animalprotection-otherphilanthropicintermediari otheractivity)
	replace ben_total = act_total + 1 if mainact!=. // count main activity also
	sum ben_total, detail
	label variable ben_total "Number of types of activities engaged in" 
	*/
	
	
	** Staff and volunteers
	
	rename staff___full_time empft
	rename staff___part_time emppt
	rename staff___casual empcl
	*rename staff_total empfte
	*replace empfte = round(empfte, 1) // round to nearest whole number
	tab staff___volunteers if missing(real(staff___volunteers))
	replace staff___volunteers = "" if missing(real(staff___volunteers))
	destring staff___volunteers, replace
	rename staff___volunteers vols
	notes : 'emp' variables measure number of staff who worked for their charity during the last pay period of the reporting period. 
	
	
	** Areas of operation
	
	codebook operates_in_*
	tab1 operates_in_*
	foreach var in act wa sa qld nt tas nsw vic {
		rename operates_in_`var' areaop_`var'
		replace areaop_`var'="1" if areaop_`var'=="y"
		replace areaop_`var'="0" if areaop_`var'=="n"
		destring areaop_`var', replace
		tab areaop_`var'
	}
	mrtab areaop_*
	
		// Create a count of the number of territories a charity operates in
		
		egen areaop_total = rowtotal(areaop_act-areaop_vic)
		list areaop_* in 1/50, clean noobs
		sum areaop_total, detail
		histogram areaop_total, fraction normal scheme(s1mono)
		label variable areaop_total "Number of territories a charity operates in"
		/*
			Vast majority (~80%) operate in one territory.
		*/

	
	** Operating countries
	
	codebook operates_overseas
	tab operates_overseas
	replace operates_overseas = "1" if operates_overseas=="y"
	replace operates_overseas = "0" if operates_overseas=="n"
	destring operates_overseas, replace
	rename operates_overseas overop
	
	/*
	
	// This is going to take a bit more work as the field contains words as well as codes e.g. NZL, New Zealand
	
	codebook operatingcountries // any countries besides Australia (hence volume of missing values)
	tab operatingcountries, sort miss // follows ISO 3166-1 alpha 3 codes
	gen overop = 0
	replace overop = 1 if operating_countries!="" // indicator of whether charity operates overseas
	label variable overop "Operates overseas"
	split operating_countries, p(",")
	tab1 operating_countries*

		// Tidy up values of the variables
		
		local counter = 1
		foreach var of varlist operating_countries1-operating_countries183  {
			gen oc`counter'=subinstr(`var'," ","",.)
			drop `var'
			local counter = `counter' + 1
		}
		
		// Grab list of country codes
		
		preserve 
			use $path3\aus\iso_country_codes_20190919.dta, clear
			rename alpha3code oc
			levelsof oc, local(levels) 
		restore
		
		// Count occurences of country across variables
		
		local counter = 1
		foreach l of local levels {
			gen country`counter' = 0 if operating_countries!=""
			label variable country`counter' "`l'"
			foreach v of varlist oc1-oc183 {
				replace country`counter' = country`counter' + 1 if `v'=="`l'"
			}
			local counter = `counter' + 1
		}
		
		egen oc_total = rowtotal(country1-country243)
		sum oc_total, detail
		sum oc_total if operating_countries!="", detail
		label variable oc_total "Number of overseas countries charity operates in"
		/*
			Is zero a sensible value? I think so i.e. no overseas countries served.
			
			Final task: get country name instead of code for labelling variables.
		*/
	*/
	
	
	** Financial information
	
	notes : Some charities were not required to answer the financial questions, such as charities ///
		that were Basic Religious Charities or Non-government schools.
		
	codebook accrual_accounting
	tab accrual_accounting
	rename accrual_accounting acctype
	label variable acctype "Type of financial accounts - cash or accrual"
	notes acctype : Charities with an ACNC size of ‘small’ were asked whether they used cash or accrual ///
		accounting during the reporting period.
	
	
	codebook type_of_financial_statement
	rename type_of_financial_statement fintype
	label variable fintype "Type of financial statement - general or special purpose"
	notes fintype : Charities that had an ACNC size of ‘medium’ or ‘large’ were asked whether they ///
		prepared either special purpose financial statements or general purpose financial ///
		statements. 

		
	** Income
	/*
		Five sources of revenue + one source of other income = total income.
		
		I will calculate HHI using five components.
	*/
	
	codebook total_gross_income
	replace total_gross_income = . if total_gross_income < 0
	rename total_gross_income itotal
	label variable itotal "Total annual gross income"
	
	// Calculate these with panel data
	
	/*
	bys ccnum: egen mninc = mean(itotal)
	bys ccnum: egen mdinc = median(itotal)
	l ccnum itotal mninc mdinc in 1/200
	foreach var in mninc mdinc {
		replace `var' = round(`var', 1)
	}
	*/
	
		// Sources of income
		
		foreach var in government_grants donations_and_bequests all_other_revenue other_income {
			replace `var' = . if `var' < 0
			replace `var' = round(`var', 1)
		}
		
		rename government_grants govern
		rename donations_and_bequests donations
		rename all_other_revenue rev_oth
		rename other_income inc_oth
		label variable donations "Income raised from donations"
		label variable govern "Income raised from government"
		label variable rev_oth "Income raised from other revenue sources"
		label variable inc_oth "Income raised from other sources e.g. sale of assets"
		
		
		// Revenue diversification
		/*
			To calculate the index: first, divide every revenue source by total revenue. Second, square all ratios. 
			Third, add. Fourth, subtract this value from 1 to rescale from 0 (less diversified) to 1 (more diversified). 
		*/
		
		capture drop inc_diverse
		gen inc_diverse =  1 - ((donations/itotal)^2 + (govern/itotal)^2 + ///
			(rev_oth/itotal)^2)
		inspect inc_diverse
		replace inc_diverse = . if inc_diverse < 0
		histogram inc_diverse, percent norm scheme(s1mono)
		sum inc_diverse, detail	
		label variable inc_diverse "Revenue diversification index - 0 (less diversified) to 1 (more diversified)"

		
		// Indicator variables
		
		gen gov = (govern > 0 & govern!=.)
		tab gov
		label variable gov "Receives funding from government"
				
		gen don_share = donations / itotal // lots of missing data, most of which are fine (i.e. itotal==0), some are puzzling...
		hist don_share, percent norm scheme(s1mono)
		replace don_share = . if donations > itotal
		l ccnum itotal donations don_share if don_share==.

		gen don_maj = 0 if don_share!=.
		replace don_maj = 1 if don_share > .50 & don_share!=.
		tab don_maj
		label variable don_maj "Derives majority of income from donations"
		label variable don_share "Share of total income derived from donations"

		
	** Expenditure
	
	codebook total_expenses
	replace total_expenses = . if total_expenses < 0
	rename total_expenses etotal
	label variable etotal "Total annual gross expenses"

	
	/*
	bys ccnum: egen mnexp = mean(etotal)
	bys ccnum: egen mdexp = median(etotal)
	l ccnum fin_year etotal mnexp mdexp in 1/200
	foreach var in mnexp mdexp {
		replace `var' = round(`var', 1)
	}
	*/
	/*
		Create log and categorical (by reporting thresholds) versions.
	*/
	
		foreach var in itotal etotal {
			gen `var'_ln = ln(`var' + 1)
		}

	
	** Employee compensation
	
	codebook employee_expenses
	replace employee_expenses = . if employee_expenses < 0
	rename employee_expenses empcomp
	label variable empcomp "Employee compensation costs"
	
		// Calculate ratio of employee compensation to total expenditure
		
		gen empcomp_share = empcomp / etotal
		hist empcomp_share, percent norm scheme(s1mono)
		replace empcomp_share = . if empcomp > etotal
	
	
	** Fundraising expenditure
	/*
		Not captured in the annual return.
	*/
		
	
	** Multiple filers
	
	codebook reporting_obligations*
 	foreach var in act wa sa qld nt tas nsw vic {
		rename reporting_obligations___`var' filed_`var'
		replace filed_`var'="1" if filed_`var'=="y"
		replace filed_`var'="0" if filed_`var'=="n"
		destring filed_`var', replace
		tab filed_`var'
	}
	mrtab filed_*
		

sort ccnum fin_year
compress
datasignature set, reset
sav $path3\aus\aus_ar_2014.dta, replace


// 2015

import excel $path2\aus\aus_ais_2015.xlsx, clear first
count
desc, f
notes : This dataset provides a record of the 2015 AISs submitted by charities, that is, the ///
	statements submitted for the 2015 reporting period. 
/*
	There are some harmonised variables with 2017.
*/

	rename *, lower
	desc, f
	
	
	// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report abn
		duplicates list abn
	
		
	// Keep relevant variables
	
	drop country
	
	
	// Keep relevant cases
	
	drop if abn==""
	
	
	// Missing data
	
	mdesc

	
	// Check variable values
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	/*
		Look for mentions of "superseded" in ccnum.
	*/

		l ccnum charity_name if regex(ccnum, "superseded")
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace
		
	
	codebook charity_name
	l charity_name in 1/50
	rename charity_name name
	label variable name "Legal name of charity"
	
	
	codebook other_organisation_names
	rename other_organisation_names name_oth
	label variable name_oth "Other name(s) of charity e.g. trading name"
	
	
	codebook charity_size // measure of reporting thresholds
	tab charity_size // Need to combine categories; first encode:
	encode charity_size, gen(rtype)
	tab charity_size rtype, nolab
	recode rtype 1 5=1 2 6=2 3 4 7=3
	label define rtype_lab 1 "Large (>= 1m)" 2 "Medium (250k - 1m)" 3 "Small (< 250k)"
	label values rtype rtype_lab
	tab rtype
	drop charity_size
	label variable rtype "Reporting threshold for charity"
	notes rtype : A charity can apply to report under a different threshold if its income for that year is anomalous ///
		i.e. income and reporting threshold might not match for a given year.

		
	codebook registration_status
	gen orgstatus = 1 if registration_status=="Registered"
	replace orgstatus = 2 if inlist(registration_status,"Revoked Compliance", "Revoked Double Defaulter", "Revoked RTS", "Revoked Registration")
	replace orgstatus = 3 if regex(registration_status, "Voluntarily")
	label define orgstatus_lab 1 "Registered" 2 "Revoked" 3 "Voluntarily Revoked"
	label values orgstatus orgstatus_lab
	tab orgstatus
	drop registration_status
	notes orgstatus : Some charities that no longer have an active registration might still have needed to ///
		lodge for 2015, or may have had their registration revoked in the time between lodging ///
		and when the dataset was generated.
	/*
		Treat this similarly to 'orgdiss'.
	*/
		
		
	codebook brc
	tab brc
	replace brc="1" if brc=="y"
	replace brc="0" if brc=="n"
	destring brc, replace
	tab brc
	label variable brc "Basic Religious Charity"
	notes brc : This subtype is exempt from regulatory requirements e.g. filing financial reports with ACNC.
	
	
	** Financial year start and end dates
	
	codebook fin_report*
	gen fys = date(fin_report_from, "DMY")
	format fys %td
	drop fin_report_from
	label variable fys "Date financial year began on"
	
	gen fye = date(fin_report_to, "DMY")
	format fys %td
	drop fin_report_to
	label variable fye "Date financial year ends on"
	
	gen fin_year = 2015
	
	
	** Submission and due dates
	
	codebook ais_due_date date_ais_received
	gen aisdue = date(ais_due_date, "DMY")
	format aisdue %td
	drop ais_due_date
	label variable aisdue "Date AIS was due (usually six months after fye)"

	gen aisfil = date(date_ais_received, "DMY")
	format aisfil %td
	drop date_ais_received
	label variable aisfil "Date AIS was filed"

	gen finfil = date(financial_report_date_received, "DMY")
	format finfil %td
	drop financial_report_date_received
	label variable finfil "Date financial report was filed"

	gen overdue = (aisfil > aisdue) // indicator of whether a charity filed late
	label variable overdue "AIS was filed late"

		
	
	** Activities
	
	codebook conducted_activities
	replace conducted_activities="1" if conducted_activities=="y"
	replace conducted_activities="0" if conducted_activities=="n"
	destring conducted_activities, replace
	tab conducted_activities
	rename conducted_activities active
	label variable active "Conducted activities during the year"
	notes active : This field records whether or not a charity conducted any activities in the reporting period.

		
	/*
	codebook main_activity
	tab main_activity 
	/*
		Similar to Rep. of Ireland approach; needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/
	encode mainactivity, gen(mainact)
	tab1 main*
	recode mainact 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainact
	tab mainactivity mainact
	label drop mainact
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainactivity
	*/
	
	codebook animal_protection-other_activity
	foreach var of varlist animal_protection-other_activity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen act_total = rowtotal(animal_protection-other_activity)
	replace act_total = act_total + 1 if main_activity!="" // count main activity also
	sum act_total, detail
	label variable act_total "Number of types of activities engaged in" 
 
		
	** Purposes
	
	codebook will_purposes_change_in_the_next
	tab will_purposes_change_in_the_next
	replace will_purposes_change_in_the_next = "1" if will_purposes_change_in_the_next=="y"
	replace will_purposes_change_in_the_next = "0" if will_purposes_change_in_the_next=="n"
	destring will_purposes_change_in_the_next, replace
	rename will_purposes_change_in_the_next purp_change
	label variable purp_change "Planning changes to charitable purposes in next reporting year"

	
	** Beneficiaries
	/*
	codebook mainbeneficiaries
	tab mainbeneficiaries 
	/*
		Needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/

	encode mainbeneficiaries, gen(mainben)
	tab1 main*
	recode mainben 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainben
	tab mainbeneficiaries mainben
	label drop mainben
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainbeneficiaries
	
	
	codebook animalprotection-otherphilanthropicintermediari otheractivity
	foreach var of varlist animalprotection-otherphilanthropicintermediari otheractivity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen ben_total = rowtotal(animalprotection-otherphilanthropicintermediari otheractivity)
	replace ben_total = act_total + 1 if mainact!=. // count main activity also
	sum ben_total, detail
	label variable ben_total "Number of types of activities engaged in" 
	*/
	
	
	** Staff and volunteers
	
	rename staff_full_time empft
	rename staff___part_time emppt
	rename staff___casual empcl
	rename staff_total empfte
	replace empfte = round(empfte, 1) // round to nearest whole number
	tab staff_volunteers if missing(real(staff_volunteers))
	replace staff_volunteers = "" if missing(real(staff_volunteers))
	destring staff_volunteers, replace
	rename staff_volunteers vols
	notes : 'emp' variables measure number of staff who worked for their charity during the last pay period of the reporting period. 
	
	
	** Areas of operation
	
	codebook operates_in_*
	tab1 operates_in_*
	foreach var in act wa sa qld nt tas nsw vic {
		rename operates_in_`var' areaop_`var'
		replace areaop_`var'="1" if areaop_`var'=="y"
		replace areaop_`var'="0" if areaop_`var'=="n"
		destring areaop_`var', replace
		tab areaop_`var'
	}
	mrtab areaop_*
	
		// Create a count of the number of territories a charity operates in
		
		egen areaop_total = rowtotal(areaop_act-areaop_vic)
		list areaop_* in 1/50, clean noobs
		sum areaop_total, detail
		histogram areaop_total, fraction normal scheme(s1mono)
		label variable areaop_total "Number of territories a charity operates in"
		/*
			Vast majority (~80%) operate in one territory.
		*/

	
	** Operating countries
	
	codebook operates_overseas
	tab operates_overseas
	replace operates_overseas = "1" if operates_overseas=="y"
	replace operates_overseas = "0" if operates_overseas=="n"
	destring operates_overseas, replace
	rename operates_overseas overop
	
	/*
	
	// This is going to take a bit more work as the field contains words as well as codes e.g. NZL, New Zealand
	
	codebook operatingcountries // any countries besides Australia (hence volume of missing values)
	tab operatingcountries, sort miss // follows ISO 3166-1 alpha 3 codes
	gen overop = 0
	replace overop = 1 if operating_countries!="" // indicator of whether charity operates overseas
	label variable overop "Operates overseas"
	split operating_countries, p(",")
	tab1 operating_countries*

		// Tidy up values of the variables
		
		local counter = 1
		foreach var of varlist operating_countries1-operating_countries183  {
			gen oc`counter'=subinstr(`var'," ","",.)
			drop `var'
			local counter = `counter' + 1
		}
		
		// Grab list of country codes
		
		preserve 
			use $path3\aus\iso_country_codes_20190919.dta, clear
			rename alpha3code oc
			levelsof oc, local(levels) 
		restore
		
		// Count occurences of country across variables
		
		local counter = 1
		foreach l of local levels {
			gen country`counter' = 0 if operating_countries!=""
			label variable country`counter' "`l'"
			foreach v of varlist oc1-oc183 {
				replace country`counter' = country`counter' + 1 if `v'=="`l'"
			}
			local counter = `counter' + 1
		}
		
		egen oc_total = rowtotal(country1-country243)
		sum oc_total, detail
		sum oc_total if operating_countries!="", detail
		label variable oc_total "Number of overseas countries charity operates in"
		/*
			Is zero a sensible value? I think so i.e. no overseas countries served.
			
			Final task: get country name instead of code for labelling variables.
		*/
	*/
	
	
	** Financial information
	
	notes : Some charities were not required to answer the financial questions, such as charities ///
		that were Basic Religious Charities or Non-government schools.
		
	codebook accrual_accounting
	tab accrual_accounting
	rename accrual_accounting acctype
	label variable acctype "Type of financial accounts - cash or accrual"
	notes acctype : Charities with an ACNC size of ‘small’ were asked whether they used cash or accrual ///
		accounting during the reporting period.
	
	
	codebook type_of_financial_statement
	rename type_of_financial_statement fintype
	label variable fintype "Type of financial statement - general or special purpose"
	notes fintype : Charities that had an ACNC size of ‘medium’ or ‘large’ were asked whether they ///
		prepared either special purpose financial statements or general purpose financial ///
		statements. 

		
	** Income
	/*
		Five sources of revenue + one source of other income = total income.
		
		I will calculate HHI using five components.
	*/
	
	codebook total_gross_income
	replace total_gross_income = . if total_gross_income < 0
	rename total_gross_income itotal
	label variable itotal "Total annual gross income"
	
	// Calculate these with panel data
	
	/*
	bys ccnum: egen mninc = mean(itotal)
	bys ccnum: egen mdinc = median(itotal)
	l ccnum itotal mninc mdinc in 1/200
	foreach var in mninc mdinc {
		replace `var' = round(`var', 1)
	}
	*/
	
		// Sources of income
		
		foreach var in government_grants donations_and_bequests all_other_revenue other_income {
			replace `var' = . if `var' < 0
			replace `var' = round(`var', 1)
		}
		
		rename government_grants govern
		rename donations_and_bequests donations
		rename all_other_revenue rev_oth
		rename other_income inc_oth
		label variable donations "Income raised from donations"
		label variable govern "Income raised from government"
		label variable rev_oth "Income raised from other revenue sources"
		label variable inc_oth "Income raised from other sources e.g. sale of assets"
		
		
		// Revenue diversification
		/*
			To calculate the index: first, divide every revenue source by total revenue. Second, square all ratios. 
			Third, add. Fourth, subtract this value from 1 to rescale from 0 (less diversified) to 1 (more diversified). 
		*/
		
		capture drop inc_diverse
		gen inc_diverse =  1 - ((donations/itotal)^2 + (govern/itotal)^2 + ///
			(rev_oth/itotal)^2)
		inspect inc_diverse
		replace inc_diverse = . if inc_diverse < 0
		histogram inc_diverse, percent norm scheme(s1mono)
		sum inc_diverse, detail	
		label variable inc_diverse "Revenue diversification index - 0 (less diversified) to 1 (more diversified)"

		
		// Indicator variables
		
		gen gov = (govern > 0 & govern!=.)
		tab gov
		label variable gov "Receives funding from government"
				
		gen don_share = donations / itotal // lots of missing data, most of which are fine (i.e. itotal==0), some are puzzling...
		hist don_share, percent norm scheme(s1mono)
		replace don_share = . if donations > itotal
		l ccnum itotal donations don_share if don_share==.

		gen don_maj = 0 if don_share!=.
		replace don_maj = 1 if don_share > .50 & don_share!=.
		tab don_maj
		label variable don_maj "Derives majority of income from donations"
		label variable don_share "Share of total income derived from donations"

		
	** Expenditure
	
	codebook total_expenses
	replace total_expenses = . if total_expenses < 0
	rename total_expenses etotal
	label variable etotal "Total annual gross expenses"

	
	/*
	bys ccnum: egen mnexp = mean(etotal)
	bys ccnum: egen mdexp = median(etotal)
	l ccnum fin_year etotal mnexp mdexp in 1/200
	foreach var in mnexp mdexp {
		replace `var' = round(`var', 1)
	}
	*/
	/*
		Create log and categorical (by reporting thresholds) versions.
	*/
	
		foreach var in itotal etotal {
			gen `var'_ln = ln(`var' + 1)
		}

	
	** Employee compensation
	
	codebook employee_expenses
	replace employee_expenses = . if employee_expenses < 0
	rename employee_expenses empcomp
	label variable empcomp "Employee compensation costs"
	
		// Calculate ratio of employee compensation to total expenditure
		
		gen empcomp_share = empcomp / etotal
		hist empcomp_share, percent norm scheme(s1mono)
		replace empcomp_share = . if empcomp > etotal
	
	
	** Fundraising expenditure
	/*
		Not captured in the annual return.
	*/
		
	
	** Multiple filers
	
	codebook reporting_obligations*
 	foreach var in act wa sa qld nt tas nsw vic {
		rename reporting_obligations_`var' filed_`var'
		replace filed_`var'="1" if filed_`var'=="y"
		replace filed_`var'="0" if filed_`var'=="n"
		destring filed_`var', replace
		tab filed_`var'
	}
	mrtab filed_*
		
	
sort ccnum fin_year	
compress
datasignature set, reset
sav $path3\aus\aus_ar_2015.dta, replace
	
		

// 2016

import excel $path2\aus\aus_ais_2016.xlsx, clear first
count
desc, f
notes : This dataset provides a record of the 2016 AISs submitted by charities, that is, the ///
	statements submitted for the 2016 reporting period. 
/*
	There are some harmonised variables with 2017.
*/

	rename *, lower
	
		// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report abn
		duplicates list abn
	
		
	// Keep relevant variables
	
	drop country
	
	
	// Keep relevant cases
	
	drop if abn==""
	
	
	// Missing data
	
	mdesc

	
	// Check variable values
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	/*
		Look for mentions of "superseded" in ccnum.
	*/

		l ccnum charityname if regex(ccnum, "superseded")
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace
		
	
	codebook charityname
	l charityname in 1/50
	rename charityname name
	label variable name "Legal name of charity"
	
	
	codebook otherorganisationnames
	rename otherorganisationnames name_oth
	label variable name_oth "Other name(s) of charity e.g. trading name"
	
	
	codebook charitysize // measure of reporting thresholds
	tab charitysize // Need to combine categories; first encode:
	encode charitysize, gen(rtype)
	tab charitysize rtype, nolab
	recode rtype 1 4=1 2 5=2 3 6=3
	label define rtype_lab 1 "Large (>= 1m)" 2 "Medium (250k - 1m)" 3 "Small (< 250k)"
	label values rtype rtype_lab
	tab rtype
	drop charitysize
	label variable rtype "Reporting threshold for charity"
	notes rtype : A charity can apply to report under a different threshold if its income for that year is anomalous ///
		i.e. income and reporting threshold might not match for a given year.
	
	
	codebook registrationstatus
	gen orgstatus = 1 if registrationstatus=="Registered"
	replace orgstatus = 2 if inlist(registrationstatus,"Revoked Compliance", "Revoked Double Defaulter", "Revoked RTS", "Revoked Registration")
	replace orgstatus = 3 if regex(registrationstatus, "Voluntarily")
	label define orgstatus_lab 1 "Registered" 2 "Revoked" 3 "Voluntarily Revoked"
	label values orgstatus orgstatus_lab
	tab orgstatus
	drop registrationstatus
	notes orgstatus : Some charities that no longer have an active registration might still have needed to ///
		lodge for 2016, or may have had their registration revoked in the time between lodging ///
		and when the dataset was generated.
	/*
		Treat this similarly to 'orgdiss'.
	*/
		
		
	codebook brc
	tab brc
	replace brc="1" if brc=="y"
	replace brc="0" if brc=="n"
	destring brc, replace
	tab brc
	label variable brc "Basic Religious Charity"
	notes brc : This subtype is exempt from regulatory requirements e.g. filing financial reports with ACNC.
	
	
	** Financial year start and end dates
	
	codebook finreport*
	gen fys = date(finreportfrom, "DMY")
	format fys %td
	drop finreportfrom
	label variable fys "Date financial year began on"
	
	gen fye = date(finreportto, "DMY")
	format fys %td
	drop finreportto
	label variable fye "Date financial year ends on"
	
	gen fin_year = 2016
	
	
	** Submission and due dates
	
	codebook aisduedate aissubmissiondate financialreportsubmissiondate
	gen aisdue = date(aisduedate, "DMY")
	format aisdue %td
	drop aisduedate
	label variable aisdue "Date AIS was due (usually six months after fye)"

	gen aisfil = date(aissubmissiondate, "DMY")
	format aisfil %td
	drop aissubmissiondate
	label variable aisfil "Date AIS was filed"

	gen finfil = date(financialreportsubmissiondate, "DMY")
	format finfil %td
	drop financialreportsubmissiondate
	label variable finfil "Date financial report was filed"

	gen overdue = (aisfil > aisdue) // indicator of whether a charity filed late
	label variable overdue "AIS was filed late"
	
	
	** Activities
	
	codebook conducted_activities
	replace conducted_activities="1" if conducted_activities=="y"
	replace conducted_activities="0" if conducted_activities=="n"
	destring conducted_activities, replace
	tab conducted_activities
	rename conducted_activities active
	label variable active "Conducted activities during the year"
	notes active : This field records whether or not a charity conducted any activities in the reporting period.

	
	codebook no_conducted_activites_reason
	l no_conducted_activites_reason if ~missing(no_conducted_activites_reason)
	rename no_conducted_activites_reason notactive_reason
	label variable notactive_reason "Reason why charity did not conduct activities this year"
	
	/*
	codebook mainactivity
	tab mainactivity 
	/*
		Similar to Rep. of Ireland approach; needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/
	encode mainactivity, gen(mainact)
	tab1 main*
	recode mainact 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainact
	tab mainactivity mainact
	label drop mainact
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainactivity
	*/
	
	codebook animalprotection-otherphilanthropicintermediari otheractivity
	foreach var of varlist animalprotection-otherphilanthropicintermediari otheractivity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen act_total = rowtotal(animalprotection-otherphilanthropicintermediari otheractivity)
	replace act_total = act_total + 1 if mainactivity!="" // count main activity also
	sum act_total, detail
	label variable act_total "Number of types of activities engaged in" 
 
	
	codebook internationalactivities*
	tab1 internationalactivities*
	foreach var in internationalother internationaltransferredfunds internationaloperatedoverseas {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	gen intact = 0 
	replace intact = 1 if inlist(1, internationalother, internationaltransferredfunds, internationaloperatedoverseas)
	label variable intact "Conducts international activities"
	
	rename internationaltransferredfunds intact_tra
	label variable intact_tra "International activity - transferring funds or goods overseas"
	
	rename internationalother intact_oth
	label variable intact_oth "International activity - other"
	
	rename internationaloperatedoverseas intact_oo
	label variable intact_oo "International activity - operating overseas"	

	
	** Purposes
	
	codebook purposechangeinnextfy
	tab purposechangeinnextfy
	replace purposechangeinnextfy = "1" if purposechangeinnextfy=="y"
	replace purposechangeinnextfy = "0" if purposechangeinnextfy=="n"
	destring purposechangeinnextfy, replace
	rename purposechangeinnextfy purp_change
	label variable purp_change "Planning changes to charitable purposes in next reporting year"

	
	** Beneficiaries
	/*
	codebook mainbeneficiaries
	tab mainbeneficiaries 
	/*
		Needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/

	encode mainbeneficiaries, gen(mainben)
	tab1 main*
	recode mainben 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainben
	tab mainbeneficiaries mainben
	label drop mainben
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainbeneficiaries
	
	
	codebook animalprotection-otherphilanthropicintermediari otheractivity
	foreach var of varlist animalprotection-otherphilanthropicintermediari otheractivity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen ben_total = rowtotal(animalprotection-otherphilanthropicintermediari otheractivity)
	replace ben_total = act_total + 1 if mainact!=. // count main activity also
	sum ben_total, detail
	label variable ben_total "Number of types of activities engaged in" 
	*/
	
	
	** Staff and volunteers
	/*
	codebook stafffulltime-staffvolunteers
	sum stafffulltime-staffvolunteers
	rename stafffulltime empft
	rename staffparttime emppt
	rename staffcasual empcl
	rename totalfulltimeequivalentstaff empfte
	replace empfte = round(empfte, 1) // round to nearest whole number
	tab staffvolunteers if missing(real(staffvolunteers))
	destring staffvolunteers, replace
	rename staffvolunteers vols
	notes : 'emp' variables measure number of staff who worked for their charity during the last pay period of the reporting period. 
	*/
	
	** Areas of operation
	
	codebook operatesinact operatesinwa operatesinsa operatesinqld operatesinnt operatesintas operatesinnsw operatesinvic
	tab1 operatesinact operatesinwa operatesinsa operatesinqld operatesinnt operatesintas operatesinnsw operatesinvic
	foreach var in act wa sa qld nt tas nsw vic {
		rename operatesin`var' areaop_`var'
		replace areaop_`var'="1" if areaop_`var'=="y"
		replace areaop_`var'="0" if areaop_`var'=="n"
		destring areaop_`var', replace
		tab areaop_`var'
	}
	mrtab areaop_*
	
		// Create a count of the number of territories a charity operates in
		
		egen areaop_total = rowtotal(areaop_act-areaop_vic)
		list areaop_* in 1/50, clean noobs
		sum areaop_total, detail
		histogram areaop_total, fraction normal scheme(s1mono)
		label variable areaop_total "Number of territories a charity operates in"
		/*
			Vast majority (~80%) operate in one territory.
		*/

	
	** Operating countries
	
	codebook operatesoverseas
	tab operatesoverseas
	replace operatesoverseas = "1" if operatesoverseas=="y"
	replace operatesoverseas = "0" if operatesoverseas=="n"
	destring operatesoverseas, replace
	rename operatesoverseas overop
	
	/*
	
	// This is going to take a bit more work as the field contains words as well as codes e.g. NZL, New Zealand
	
	codebook operatingcountries // any countries besides Australia (hence volume of missing values)
	tab operatingcountries, sort miss // follows ISO 3166-1 alpha 3 codes
	gen overop = 0
	replace overop = 1 if operating_countries!="" // indicator of whether charity operates overseas
	label variable overop "Operates overseas"
	split operating_countries, p(",")
	tab1 operating_countries*

		// Tidy up values of the variables
		
		local counter = 1
		foreach var of varlist operating_countries1-operating_countries183  {
			gen oc`counter'=subinstr(`var'," ","",.)
			drop `var'
			local counter = `counter' + 1
		}
		
		// Grab list of country codes
		
		preserve 
			use $path3\aus\iso_country_codes_20190919.dta, clear
			rename alpha3code oc
			levelsof oc, local(levels) 
		restore
		
		// Count occurences of country across variables
		
		local counter = 1
		foreach l of local levels {
			gen country`counter' = 0 if operating_countries!=""
			label variable country`counter' "`l'"
			foreach v of varlist oc1-oc183 {
				replace country`counter' = country`counter' + 1 if `v'=="`l'"
			}
			local counter = `counter' + 1
		}
		
		egen oc_total = rowtotal(country1-country243)
		sum oc_total, detail
		sum oc_total if operating_countries!="", detail
		label variable oc_total "Number of overseas countries charity operates in"
		/*
			Is zero a sensible value? I think so i.e. no overseas countries served.
			
			Final task: get country name instead of code for labelling variables.
		*/
	*/
	
	
	** Financial information
	
	notes : Some charities were not required to answer the financial questions, such as charities ///
		that were Basic Religious Charities or Non-government schools.
		
	codebook accrualaccounting
	tab accrualaccounting
	rename accrualaccounting acctype
	label variable acctype "Type of financial accounts - cash or accrual"
	notes acctype : Charities with an ACNC size of ‘small’ were asked whether they used cash or accrual ///
		accounting during the reporting period.
	
	
	codebook typeoffinancialstatement
	rename typeoffinancialstatement fintype
	label variable fintype "Type of financial statement - general or special purpose"
	notes fintype : Charities that had an ACNC size of ‘medium’ or ‘large’ were asked whether they ///
		prepared either special purpose financial statements or general purpose financial ///
		statements. 

		
	** Income
	/*
		Five sources of revenue + one source of other income = total income.
		
		I will calculate HHI using five components.
	*/
	
	codebook totalgrossincome
	replace totalgrossincome = . if totalgrossincome < 0
	rename totalgrossincome itotal
	label variable itotal "Total annual gross income"
	
	// Calculate these with panel data
	
	/*
	bys ccnum: egen mninc = mean(itotal)
	bys ccnum: egen mdinc = median(itotal)
	l ccnum itotal mninc mdinc in 1/200
	foreach var in mninc mdinc {
		replace `var' = round(`var', 1)
	}
	*/
	
		// Sources of income
		
		foreach var in governmentgrants donationsandbequests allotherrevenue otherincome {
			replace `var' = . if `var' < 0
			replace `var' = round(`var', 1)
		}
		
		rename governmentgrants govern
		rename donationsandbequests donations
		rename allotherrevenue rev_oth
		rename otherincome inc_oth
		label variable donations "Income raised from donations"
		label variable govern "Income raised from government"
		label variable rev_oth "Income raised from other revenue sources"
		label variable inc_oth "Income raised from other sources e.g. sale of assets"
		
		
		// Revenue diversification
		/*
			To calculate the index: first, divide every revenue source by total revenue. Second, square all ratios. 
			Third, add. Fourth, subtract this value from 1 to rescale from 0 (less diversified) to 1 (more diversified). 
		*/
		
		capture drop inc_diverse
		gen inc_diverse =  1 - ((donations/itotal)^2 + (govern/itotal)^2 + ///
			(rev_oth/itotal)^2)
		inspect inc_diverse
		replace inc_diverse = . if inc_diverse < 0
		histogram inc_diverse, percent norm scheme(s1mono)
		sum inc_diverse, detail	
		label variable inc_diverse "Revenue diversification index - 0 (less diversified) to 1 (more diversified)"

		
		// Indicator variables
		
		gen gov = (govern > 0 & govern!=.)
		tab gov
		label variable gov "Receives funding from government"
				
		gen don_share = donations / itotal // lots of missing data, most of which are fine (i.e. itotal==0), some are puzzling...
		hist don_share, percent norm scheme(s1mono)
		replace don_share = . if donations > itotal
		l ccnum itotal donations don_share if don_share==.

		gen don_maj = 0 if don_share!=.
		replace don_maj = 1 if don_share > .50 & don_share!=.
		tab don_maj
		label variable don_maj "Derives majority of income from donations"
		label variable don_share "Share of total income derived from donations"

		
	** Expenditure
	
	codebook totalexpenses
	replace totalexpenses = . if totalexpenses < 0
	rename totalexpenses etotal
	label variable etotal "Total annual gross expenses"

	
	/*
	bys ccnum: egen mnexp = mean(etotal)
	bys ccnum: egen mdexp = median(etotal)
	l ccnum fin_year etotal mnexp mdexp in 1/200
	foreach var in mnexp mdexp {
		replace `var' = round(`var', 1)
	}
	*/
	/*
		Create log and categorical (by reporting thresholds) versions.
	*/
	
		foreach var in itotal etotal {
			gen `var'_ln = ln(`var' + 1)
		}

	
	** Employee compensation
	
	codebook employeeexpenses
	replace employeeexpenses = . if employeeexpenses < 0
	rename employeeexpenses empcomp
	label variable empcomp "Employee compensation costs"
	
		// Calculate ratio of employee compensation to total expenditure
		
		gen empcomp_share = empcomp / etotal
		hist empcomp_share, percent norm scheme(s1mono)
		replace empcomp_share = . if empcomp > etotal
	
	
	** Fundraising expenditure
	/*
		Not captured in the annual return.
	*/
		
	
	** Multiple filers
	
	codebook reportingobligations*
 	foreach var in act wa sa qld nt tas nsw vic {
		rename reportingobligations`var' filed_`var'
		replace filed_`var'="1" if filed_`var'=="y"
		replace filed_`var'="0" if filed_`var'=="n"
		destring filed_`var', replace
		tab filed_`var'
	}
	mrtab filed_*
	
	
	** Incorporated
	/*
	codebook incorporatedassociation
	tab incorporatedassociation
	rename incorporatedassociation incorp
	replace incorp="1" if incorp=="y"
	replace incorp="0" if incorp=="n"
	destring incorp, replace
	tab incorp
	label variable incorp "Incorporated association"

	
	codebook associationnumber* // it appears incorporated charities have a company number specific to a territory
	tab1 associationnumber*
	*gen icnum
	/*
		Can a charity have association numbers in multipe territories?
	*/
	*label variable icnum "Incorporated association number"

	
	** Fundraising locations
	
	codebook fundraising*
	foreach var in act wa sa qld nt tas nsw vic {
		rename fundraising`var' fundraising_`var'
		replace fundraising_`var'="1" if fundraising_`var'=="y"
		replace fundraising_`var'="0" if fundraising_`var'=="n"
		destring fundraising_`var', replace
		tab fundraising_`var'
	}
	mrtab fundraising_*
*/	
	
sort ccnum fin_year	
compress
datasignature set, reset
sav $path3\aus\aus_ar_2016.dta, replace
	

// 2017

import excel $path2\aus\aus_ais_2017.xlsx, clear first
count
desc, f
notes : This dataset provides a record of the 2017 AISs submitted by charities, that is, the ///
	statements submitted for the 2017 reporting period. 

	// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report abn
		duplicates list abn
	
		
	// Keep relevant variables
	
	drop country
	
	
	// Keep relevant cases
	
	drop if abn==""
	
	
	// Missing data
	
	mdesc

	
	// Check variable values
	
	codebook abn
	rename abn ccnum
	label variable ccnum "Unique id of charity - Australian Business Number"
	/*
		Look for mentions of "superseded" in ccnum.
	*/

		l ccnum charityname if regex(ccnum, "superseded")
		capture replace ccnum = "" if missing(real(ccnum))
		capture destring ccnum, replace
		
	
	codebook charityname
	l charityname in 1/50
	rename charityname name
	label variable name "Legal name of charity"
	
	
	codebook otherorganisationnames
	rename otherorganisationnames name_oth
	label variable name_oth "Other name(s) of charity e.g. trading name"
	
	
	codebook charitysize // measure of reporting thresholds
	tab charitysize // Need to combine categories; first encode:
	encode charitysize, gen(rtype)
	tab charitysize rtype, nolab
	recode rtype 1 2=1 3 4 7=2 5 6 8=3
	label define rtype_lab 1 "Large (>= 1m)" 2 "Medium (250k - 1m)" 3 "Small (< 250k)"
	label values rtype rtype_lab
	tab rtype
	drop charitysize
	label variable rtype "Reporting threshold for charity"
	notes rtype : A charity can apply to report under a different threshold if its income for that year is anomalous ///
		i.e. income and reporting threshold might not match for a given year.
	
	
	codebook RegistrationStatus
	gen orgstatus = 1 if RegistrationStatus=="REG"
	replace orgstatus = 2 if RegistrationStatus=="REV"
	replace orgstatus = 3 if RegistrationStatus=="VREV"
	label define orgstatus_lab 1 "Registered" 2 "Revoked" 3 "Voluntarily Revoked"
	label values orgstatus orgstatus_lab
	tab orgstatus
	drop RegistrationStatus
	notes orgstatus : Some charities that no longer have an active registration might still have needed to ///
		lodge for 2017, or may have had their registration revoked in the time between lodging ///
		and when the dataset was generated.
		
		
	codebook basicreligiouscharity
	tab basicreligiouscharity
	replace basicreligiouscharity="1" if basicreligiouscharity=="y"
	replace basicreligiouscharity="0" if basicreligiouscharity=="n"
	destring basicreligiouscharity, replace
	tab basicreligiouscharity
	rename basicreligiouscharity brc
	label variable brc "Basic Religious Charity"
	notes brc : This subtype is exempt from regulatory requirements e.g. filing financial reports with ACNC.
	
	
	** Financial year start and end dates
	
	codebook finreport*
	gen fys = date(finreportfrom, "DMY")
	format fys %td
	drop finreportfrom
	label variable fys "Date financial year began on"
	
	gen fye = date(finreportto, "DMY")
	format fys %td
	drop finreportto
	label variable fye "Date financial year ends on"
	
	gen fin_year = 2017

	
	** Submission and due dates
	
	codebook aisduedate dateaisreceived financialrepo~d
	gen aisdue = date(aisduedate, "DMY")
	format aisdue %td
	drop aisduedate
	label variable aisdue "Date AIS was due (usually six months after fye)"

	gen aisfil = date(dateaisreceived, "DMY")
	format aisfil %td
	drop dateaisreceived
	label variable aisfil "Date AIS was filed"

	gen finfil = date(financialreportdatereceived, "DMY")
	format finfil %td
	drop financialreportdatereceived
	label variable finfil "Date financial report was filed"

	gen overdue = (aisfil > aisdue) // indicator of whether a charity filed late
	label variable overdue "AIS was filed late"
	
	
	** Activities
	
	codebook conductedactivities
	replace conductedactivities="1" if conductedactivities=="y"
	replace conductedactivities="0" if conductedactivities=="n"
	destring conductedactivities, replace
	tab conductedactivities
	rename conductedactivities active
	label variable active "Conducted activities during the year"
	notes active : This field records whether or not a charity conducted any activities in the reporting period.

	
	codebook whycharitydidnotconductacti
	l whycharitydidnotconductacti if ~missing(whycharitydidnotconductacti)
	rename whycharitydidnotconductacti notactive_reason
	label variable notactive_reason "Reason why charity did not conduct activities this year"
	
	codebook mainactivity
	tab mainactivity 
	/*
		Similar to Rep. of Ireland approach; needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/
	encode mainactivity, gen(mainact)
	tab1 main*
	recode mainact 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainact
	tab mainactivity mainact
	label drop mainact
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainactivity
	
	
	codebook animalprotection-otherphilanthropicintermediari otheractivity
	foreach var of varlist animalprotection-otherphilanthropicintermediari otheractivity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen act_total = rowtotal(animalprotection-otherphilanthropicintermediari otheractivity)
	replace act_total = act_total + 1 if mainact!=. // count main activity also
	sum act_total, detail
	label variable act_total "Number of types of activities engaged in" 
 
	
	codebook *internationalactivities*
	tab1 *internationalactivities* AT 
	foreach var in internationalactivities internationalactivitiesunderta otherinternationalactivities AT {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	rename internationalactivities intact
	label variable intact "Conducts international activities"
	
	rename internationalactivitiesunderta intact_tra
	label variable intact_tra "International activity - transferring funds or goods overseas"
	
	rename otherinternationalactivities intact_oth
	label variable intact_oth "International activity - other"
	
	rename AT intact_oo
	label variable intact_oo "International activity - operating overseas"	

	
	** Purposes
	
	codebook willpurposeschangeinthenext
	tab willpurposeschangeinthenext
	replace willpurposeschangeinthenext = "1" if willpurposeschangeinthenext=="y"
	replace willpurposeschangeinthenext = "0" if willpurposeschangeinthenext=="n"
	destring willpurposeschangeinthenext, replace
	rename willpurposeschangeinthenext purp_change
	label variable purp_change "Planning changes to charitable purposes in next reporting year"

	
	** Beneficiaries
	
	codebook mainbeneficiaries
	tab mainbeneficiaries 
	/*
		Needs normalising to 26 categories (see User guide – 2017 Annual Information Statement data)
	*/
	/*
	encode mainbeneficiaries, gen(mainben)
	tab1 main*
	recode mainben 4=1 2 3=2 5 1=3 6=4 7=5 8=6 9=7 10=8 11=9 12=10 13=11 14=12 15=13 16=14 17=15 18=. 19=16 26=17 27 28=18 29=19 ///
		31=20 32=21 21=22 22=23 20 24 25=24 23=25 *=.
	codebook mainben
	tab mainbeneficiaries mainben
	label drop mainben
	label define mainact_lab 1 "Animal protection" 2 "Aged care" 3 "Civic and advocacy activities" 4 "Culture and arts" ///
		5 "Economic, social and community development" 6 "Emergency relief" 7 "Employment and training" 8 "Environmental activities" ///
		9 "Grant-making activities" 10 "Higher education" 11 "Hospital services and rehabilitation activities" 12 "Housing activities" ///
		13 "Income support and maintenance" 14 "International activities" 15 "Law and legal services" 16 "Mental health and crisis intervention" ///
		17 "Primary and secondary education" 18 "Religious activities" 19 "Research" 20 "Social Services" 21 "Sports" ///
		22 "Other education" 23 "Other health service delivery" 24 "Other recreation" 25 "Other philanthropic intermediaries and voluntarism promotion" ///
		26 "Other activity"
	label values mainact mainact_lab
	drop mainbeneficiaries
	
	
	codebook animalprotection-otherphilanthropicintermediari otheractivity
	foreach var of varlist animalprotection-otherphilanthropicintermediari otheractivity {
		replace `var' = "1" if `var'=="y"
		replace `var' = "0" if `var'=="n"
		destring `var', replace
		tab `var'
	}
	egen ben_total = rowtotal(animalprotection-otherphilanthropicintermediari otheractivity)
	replace ben_total = act_total + 1 if mainact!=. // count main activity also
	sum ben_total, detail
	label variable ben_total "Number of types of activities engaged in" 
	*/
	
	
	** Staff and volunteers
	
	codebook stafffulltime-staffvolunteers
	sum stafffulltime-staffvolunteers
	rename stafffulltime empft
	rename staffparttime emppt
	rename staffcasual empcl
	rename totalfulltimeequivalentstaff empfte
	replace empfte = round(empfte, 1) // round to nearest whole number
	tab staffvolunteers if missing(real(staffvolunteers))
	destring staffvolunteers, replace
	rename staffvolunteers vols
	notes : 'emp' variables measure number of staff who worked for their charity during the last pay period of the reporting period. 

	
	** Areas of operation
	
	codebook operatesinact operatesinwa operatesinsa operatesinqld operatesinnt operatesintas operatesinnsw operatesinvic
	tab1 operatesinact operatesinwa operatesinsa operatesinqld operatesinnt operatesintas operatesinnsw operatesinvic
	foreach var in act wa sa qld nt tas nsw vic {
		rename operatesin`var' areaop_`var'
		replace areaop_`var'="1" if areaop_`var'=="y"
		replace areaop_`var'="0" if areaop_`var'=="n"
		destring areaop_`var', replace
		tab areaop_`var'
	}
	mrtab areaop_*
	
		// Create a count of the number of territories a charity operates in
		
		egen areaop_total = rowtotal(areaop_act-areaop_vic)
		list areaop_* in 1/50, clean noobs
		sum areaop_total, detail
		histogram areaop_total, fraction normal scheme(s1mono)
		label variable areaop_total "Number of territories a charity operates in"
		/*
			Vast majority (~80%) operate in one territory.
		*/

	
	** Operating countries
	
	codebook operatesoverseas
	tab operatesoverseas
	replace operatesoverseas = "1" if operatesoverseas=="y"
	replace operatesoverseas = "0" if operatesoverseas=="n"
	destring operatesoverseas, replace
	rename operatesoverseas overop
	
	/*
	
	// This is going to take a bit more work as the field contains words as well as codes e.g. NZL, New Zealand
	
	codebook operatingcountries // any countries besides Australia (hence volume of missing values)
	tab operatingcountries, sort miss // follows ISO 3166-1 alpha 3 codes
	gen overop = 0
	replace overop = 1 if operating_countries!="" // indicator of whether charity operates overseas
	label variable overop "Operates overseas"
	split operating_countries, p(",")
	tab1 operating_countries*

		// Tidy up values of the variables
		
		local counter = 1
		foreach var of varlist operating_countries1-operating_countries183  {
			gen oc`counter'=subinstr(`var'," ","",.)
			drop `var'
			local counter = `counter' + 1
		}
		
		// Grab list of country codes
		
		preserve 
			use $path3\aus\iso_country_codes_20190919.dta, clear
			rename alpha3code oc
			levelsof oc, local(levels) 
		restore
		
		// Count occurences of country across variables
		
		local counter = 1
		foreach l of local levels {
			gen country`counter' = 0 if operating_countries!=""
			label variable country`counter' "`l'"
			foreach v of varlist oc1-oc183 {
				replace country`counter' = country`counter' + 1 if `v'=="`l'"
			}
			local counter = `counter' + 1
		}
		
		egen oc_total = rowtotal(country1-country243)
		sum oc_total, detail
		sum oc_total if operating_countries!="", detail
		label variable oc_total "Number of overseas countries charity operates in"
		/*
			Is zero a sensible value? I think so i.e. no overseas countries served.
			
			Final task: get country name instead of code for labelling variables.
		*/
	*/
	
	
	** Financial information
	
	notes : Some charities were not required to answer the financial questions, such as charities ///
		that were Basic Religious Charities or Non-government schools.
		
	codebook cashoraccrual
	tab cashoraccrual
	rename cashoraccrual acctype
	label variable acctype "Type of financial accounts - cash or accrual"
	notes acctype : Charities with an ACNC size of ‘small’ were asked whether they used cash or accrual ///
		accounting during the reporting period.
	
	
	codebook typeoffinancialstatement
	rename typeoffinancialstatement fintype
	label variable fintype "Type of financial statement - general or special purpose"
	notes fintype : Charities that had an ACNC size of ‘medium’ or ‘large’ were asked whether they ///
		prepared either special purpose financial statements or general purpose financial ///
		statements. 

		
	** Income
	/*
		Five sources of revenue + one source of other income = total income.
		
		I will calculate HHI using five components.
	*/
	
	codebook totalgrossincome
	replace totalgrossincome = . if totalgrossincome < 0
	rename totalgrossincome itotal
	label variable itotal "Total annual gross income"
	
	// Calculate these with panel data
	
	/*
	bys ccnum: egen mninc = mean(itotal)
	bys ccnum: egen mdinc = median(itotal)
	l ccnum itotal mninc mdinc in 1/200
	foreach var in mninc mdinc {
		replace `var' = round(`var', 1)
	}
	*/
	
		// Sources of income
		
		foreach var in revenuefromgovernment donationsandbequests revenuefromgoodsandservices revenuefrominvestments allotherrevenue otherincome {
			replace `var' = . if `var' < 0
			replace `var' = round(`var', 1)
		}
		
		rename revenuefromgovernment govern
		rename donationsandbequests donations
		rename revenuefromgoodsandservices fees
		rename revenuefrominvestments invest
		rename allotherrevenue rev_oth
		rename otherincome inc_oth
		label variable donations "Income raised from donations"
		label variable govern "Income raised from government"
		label variable fees "Income raised from sale of goods or services"
		label variable invest "Income raised from investments"
		label variable rev_oth "Income raised from other revenue sources"
		label variable inc_oth "Income raised from other sources e.g. sale of assets"
		
		
		// Revenue diversification
		/*
			To calculate the index: first, divide every revenue source by total revenue. Second, square all ratios. 
			Third, add. Fourth, subtract this value from 1 to rescale from 0 (less diversified) to 1 (more diversified). 
		*/
		
		capture drop inc_diverse
		gen inc_diverse =  1 - ((donations/itotal)^2 + (govern/itotal)^2 + ///
			(fees/itotal)^2 + (invest/itotal)^2 + (rev_oth/itotal)^2)
		inspect inc_diverse
		replace inc_diverse = . if inc_diverse < 0
		histogram inc_diverse, percent norm scheme(s1mono)
		sum inc_diverse, detail	
		label variable inc_diverse "Revenue diversification index - 0 (less diversified) to 1 (more diversified)"

		
		// Indicator variables
		
		gen gov = (govern > 0 & govern!=.)
		tab gov
		label variable gov "Receives funding from government"
				
		gen don_share = donations / itotal // lots of missing data, most of which are fine (i.e. itotal==0), some are puzzling...
		hist don_share, percent norm scheme(s1mono)
		replace don_share = . if donations > itotal
		l ccnum itotal donations don_share if don_share==.

		gen don_maj = 0 if don_share!=.
		replace don_maj = 1 if don_share > .50 & don_share!=.
		tab don_maj
		label variable don_maj "Derives majority of income from donations"
		label variable don_share "Share of total income derived from donations"

	
	** Debt level and investment income
	/*
		Speak to Carolyn about operationalising these a la Lu et al. (2019).
	*/	
	
	gen invest_share = invest / itotal
	hist invest_share, percent norm scheme(s1mono)
	replace invest_share = . if invest > itotal
	l ccnum itotal invest invest_share if invest_share==.
	label variable invest_share "Share of total income derived from donations"
		
	
	** Expenditure
	
	codebook totalexpenses
	replace totalexpenses = . if totalexpenses < 0
	rename totalexpenses etotal
	label variable etotal "Total annual gross expenses"

	
	/*
	bys ccnum: egen mnexp = mean(etotal)
	bys ccnum: egen mdexp = median(etotal)
	l ccnum fin_year etotal mnexp mdexp in 1/200
	foreach var in mnexp mdexp {
		replace `var' = round(`var', 1)
	}
	*/
	/*
		Create log and categorical (by reporting thresholds) versions.
	*/
	
		foreach var in itotal etotal {
			gen `var'_ln = ln(`var' + 1)
		}

	
	** Employee compensation
	
	codebook employeeexpenses
	replace employeeexpenses = . if employeeexpenses < 0
	rename employeeexpenses empcomp
	label variable empcomp "Employee compensation costs"
	
		// Calculate ratio of employee compensation to total expenditure
		
		gen empcomp_share = empcomp / etotal
		hist empcomp_share, percent norm scheme(s1mono)
		replace empcomp_share = . if empcomp > etotal
	
	
	** Fundraising expenditure
	/*
		Not captured in the annual return.
	*/
		
	
	** Multiple filers
	
	codebook submittedreport*
 	foreach var in act wa sa qld nt tas nsw vic {
		rename submittedreport`var' filed_`var'
		replace filed_`var'="1" if filed_`var'=="y"
		replace filed_`var'="0" if filed_`var'=="n"
		destring filed_`var', replace
		tab filed_`var'
	}
	mrtab filed_*
	
	tab whydidcharityhavetosubmitt
	
	
	** Incorporated
	
	codebook incorporatedassociation
	tab incorporatedassociation
	rename incorporatedassociation incorp
	replace incorp="1" if incorp=="y"
	replace incorp="0" if incorp=="n"
	destring incorp, replace
	tab incorp
	label variable incorp "Incorporated association"

	
	codebook associationnumber* // it appears incorporated charities have a company number specific to a territory
	tab1 associationnumber*
	*gen icnum
	/*
		Can a charity have association numbers in multipe territories?
	*/
	*label variable icnum "Incorporated association number"

	
	** Fundraising locations
	
	codebook fundraising*
	foreach var in act wa sa qld nt tas nsw vic {
		rename fundraising`var' fundraising_`var'
		replace fundraising_`var'="1" if fundraising_`var'=="y"
		replace fundraising_`var'="0" if fundraising_`var'=="n"
		destring fundraising_`var', replace
		tab fundraising_`var'
	}
	mrtab fundraising_*
	
	
sort ccnum fin_year
compress
datasignature set, reset
sav $path3\aus\aus_ar_2017.dta, replace
	
	
/** 2. Merge data sets **/

** Annual Returns **
/*
	Append the different data files, keeping key variables.
*/

use $path3\aus\aus_ar_2017.dta, clear

forvalues i = 2013/2016 {
	append using $path3\aus\aus_ar_`i'.dta, force
}

keep ccnum name active brc fin_year rtype act_total areaop_total inc_diverse gov don_share don_maj itotal* etotal* empcomp_share vols
sort fin_year

	// Derived variables
	
	quietly distinct ccnum
	di "`r(ndistinct)' charities have submitted an annual return between 2013-2017"
	mdesc
	tab fin_year if don_share==.
	
	
	** Most recent annual return
	
	bysort ccnum: egen maxret = max(fin_year)
	gen latestreturn = maxret==fin_year

	
	** Size
	
	bys ccnum: egen mninc = mean(itotal)
	bys ccnum: egen mdinc = median(itotal)
	l ccnum fin_year itotal mninc mdinc in 1/200
	foreach var in mninc mdinc {
		replace `var' = round(`var', 1)
	}
	
	bys ccnum: egen mnexp = mean(etotal)
	bys ccnum: egen mdexp = median(etotal)
	l ccnum fin_year etotal mnexp mdexp in 1/200
	foreach var in mnexp mdexp {
		replace `var' = round(`var', 1)
	}

		foreach var in mninc mdinc mnexp mdexp {
			gen `var'_ln = ln(`var' + 1)
		}
	

compress
datasignature set, reset
sav $path3\aus\aus_ar_2013_2017.dta, replace

	// Save a version containing only latest annual return and summary measures (e.g. mdinc)

	use "$path3\aus\aus_ar_2013_2017.dta", clear
		
		keep if latestreturn==1
		duplicates report ccnum
		duplicates drop ccnum, force
	
	sort ccnum
	sav "$path1\aus_ar_latest.dta", replace
	

** Revocations **
	
// Merge list of charity web ids with revocation data

use $path3\aus\aus_revocation_20190921.dta, clear
sort cwid
merge m:1 cwid using $path3\aus\aus_webids_20190919.dta, keep(match master) keepus(ccnum)
drop _merge

	capture tab ccnum if missing(real(ccnum))
	capture replace ccnum = "" if missing(real(ccnum))
	capture destring ccnum, replace

	duplicates report ccnum
	duplicates list ccnum
	duplicates drop ccnum, force

sort ccnum

sav $path3\aus\aus_revocation_20190921.dta, replace

/*
// Merge charity register with revocation data (long format)

use $path3\aus\aus_revocation_20190921.dta, clear
sort ccnum

merge m:1 ccnum using $path3\aus\aus_charreg_analysis_20190910.dta, keep(match master)
*/

** Charity Register **
/*
	Merge revocation data with charity register.
*/

use $path3\aus\aus_charreg_20190910.dta, clear
sort ccnum
merge 1:1 ccnum using $path3\aus\aus_revocation_20190921.dta, keep(match master)
drop _merge

merge 1:1 ccnum using $path1\aus_ar_latest.dta, keep(match master)
rename _merge ar_merge

	// Derived variables
	/*
		Theoretical model being tested (see written notes on this):
	
		- Population ecology:
			* Size
			* Age
			* Sector
			* Density (by sector or area)
		- New institutionalism (not sure I have measures of these):
			* Legitmacy (could be government funding; links with other charities - through trustees)
			* Conformance to codes/rule etc
		- Resource dependence (see Lu et al. 2019 for operationalisations):
			* Donative vs commercial
			* Main source of funds (e.g. public funding)
			* Revenue diversification
		- Controls:
			* Year (active, not registered as this is captured in age) [only possible with panel data]
			* Board size
			* Volunteer hours or numbers (McHargue 2003)
	*/	

	** Dependent variables
	
	tab1 orgdiss
	replace orgdiss = 0 if orgdiss==.
	
	gen deregistered = orgdiss
	recode deregistered 0=0 1/4=1
	tab deregistered orgdiss
	
	
	** Sector
	/*
		Get this from annual returns.
	*/
	
	
	** Size
	/*
		Use reporting threshold and a measure from the annual returns.
	*/	
	
	tab rtype
	sum mninc, detail
	
	
	** Age
	
	tab1 orgdiss statusy esty fin_year
	gen orgage = .
	replace orgage = 2019 - esty if orgdiss==0 // for registered charities, their age is 2019 minus year established
	replace orgage = statusy - esty if orgdiss > 0 // for deregistered charities, their age is removal year minue year established
	sum orgage, detail
	hist orgage, percent norm scheme(s1mono)
	replace orgage = . if orgage < 0
	
	
	** Board size
	
	tab orgct
	
	
	** Volunteer hours or numbers
	/*
		Get from annual returns.
	*/
	
	codebook vols
	
	
compress
datasignature set, reset	
sav $path3\aus\aus_charreg_analysis_20190910.dta, replace
