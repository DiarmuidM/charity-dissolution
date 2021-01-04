// File: istr_ew_data-cleaning.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 19/04/2018

******* England & Wales Register of Charities data cleaning *******

/* This DO file performs the following tasks:
	- imports raw data in csv format
	- cleans these datasets
	- links these datasets together to form a comprehensive Register of Charities and a financial panel dataset
	- saves these datasets in Stata and CSV formats
   
	The Register of Charities is the base dataset that the rest are merged with.
   
   
   Remaining tasks:
	- same variables as NCVO dataset used in Leverhulme project (i.e. postcode lookup variables, latest financial)
   
*/


/* Define paths */

global dfiles "C:\Users\t95171dm\Dropbox\voluntas-paper" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-dissolution" // location of syntax and other project outputs
global fdate : di %tdCY-N-D daily("$S_DATE", "DMY")
di "$fdate"

include "$rfiles\syntax\project-paths.doi"


/* extract_registration dataset */	

import delimited using $path2\ew\extract_registration.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
			
	keep if subno==0

	codebook regdate remdate // Variables are currently strings, need to extract info in YYYYMMDD format.
	gen diss_year = substr(remdate, 1,4)
	destring diss_year, replace
			
	keep regno diss_year remcode
	duplicates drop regno, force
	
sav $path1\ew-regrem-`fdate'.dta, replace


/* Masterfile of E&W charities */

use "C:\Users\t95171dm\Dropbox\esrc-finvul-data\data-raw\CCdata_Sept2020.dta", clear

	rename cceid regno
	duplicates drop regno, force
	
	
	** Keep relevant variables **
	
	keep regno aob icnpo_ncvo_category reg_year scale coyno imd_decile_2019 isreg ///
		FH_income_def* FH_fye_date*
		
	rename *_def# *# // remove "_def" from variable names

	
	** Merge with registration dataset **
	
	merge 1:1 regno using $path1\ew-regrem-`fdate'.dta, keep(match master)
	

	** Reshape to wide **
	/*
	reshape long FH_income FH_fye_date , i(regno) j(fin_year)
	tab fin_year
	
	duplicates drop regno fin_year, force // drop duplicate observations for the same financial year
	drop if FH_income==.
	drop if regno==.
	

	** Examine variable values **
	
	// Date variables
	
	rename FH_fye_date fyend
	
	
	// Identify most recent financial return (> 2017)
	
	bys regno: egen fin_year_mr = max(fin_year)
	tab1 fin_year*
	gen fin_year_cs =  (fin_year == fin_year_mr & fin_year > 2017)
	label variable fin_year_cs "Most recent financial year (2017 onwards)"
	label variable fin_year_mr "Most recent financial year"
	label variable fin_year "Calendar year a charity's financial year ends in"
	*/
	
	** Derived variables **
	
	// One record per charity
	
	*egen pickone = tag(regno)

	
	// ICNPO
	
	replace icnpo_ncvo_category="Other" if icnpo_ncvo_category=="Playgroups and nurseries" | icnpo_ncvo_category=="Scout groups and youth clubs" ///
		| icnpo_ncvo_category=="NULL" | icnpo_ncvo_category=="Parent Teacher Associations" | icnpo_ncvo_category=="Village Halls"
	encode icnpo_ncvo_category, gen(icnpo_ncvo_category_num)
	
	
	// Organisation age
	
	gen orgage = cond(diss_year==., 2020 - reg_year, diss_year - reg_year)
	egen orgage_cat = cut(orgage), at(0 10 25 50 100)
	sum orgage
	label define orgage_lab 1 "0-9" 2 "10-24" 3 "25-49" 4 "50+"
	label values orgage_cat orgage_lab
	tab orgage_cat
	
	
	// Organisation size
	/*
	gen orgsize = ln(FH_income + 1)
	gen orgsize = orgsize_all if fin_year==fin_year_mr
	sort regno orgsize
	bys regno : replace orgsize = orgsize[1] if orgsize==.
	*/
	
	// Organisation type
	
	gen incorp = (!missing(coyno)) // some additional data cleaning necessary (& coyno != regno_str)
	tab incorp
	
	
	// Removed
	
	capture drop dereg
	gen dereg = (isreg=="RM")
	tab dereg isreg
	label variable dereg "Organisation no longer registered as a charity"
	
	
	// Multinomial measure of removed reason
	/*
		Map to conceptual framework.
	*/
	
	tab1 remcode*
	replace remcode = trim(remcode)
	capture drop dissolution
	gen dissolution = .
	replace dissolution = 0 if isreg=="R"
	replace dissolution = 1 if remcode=="CE" | remcode=="NO"
	replace dissolution = 2 if remcode=="CC" | remcode=="POL" | remcode=="REG" | remcode=="VR"
	replace dissolution = 3 if remcode=="A"
	tab dissolution
	label define rem_label 0 "Registered" 1 "Org Death" 2 "Revocation" 3 "Rebirth"
	label values dissolution rem_label
	label variable dissolution "Indicates whether a charity has been de-registered and for what reason"


	** Keep variables and observations for analysis **
	
	keep regno icnpo* dissolution dereg incorp orgage* scale reg_year diss_year

	
compress
sav $path3\ew-dissolution-analysis.dta, replace










































/* 1. Open the raw data in csv format */

/* Base dataset - extract_charity */

import delimited using $path2\ew\extract_charity.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
label data "One observation per registered/removed charity (including subsidiaries)"
**codebook *, problems

/*
		- remove problematic variables/cases e.g. duplicate records, missing values etc
		- sort data by unique identifier
		- explore invalid values for each variable
		- label variables/values/dataset
*/


	/* Missing or duplicate values */
	
	capture ssc install mdesc
	mdesc
	missings dropvars, force
	
	duplicates report // Lots of duplicates
	duplicates list // Look to be data entry errors: every variable is blank except regno, which is a string (e.g. "AS AMENDED ON 27/11/2011&#x0D;").
	duplicates drop
	
	duplicates report regno
	duplicates list regno // Looks like a combination of data entry errors (strings again) and duplicate numbers. Delete strings first.
	duplicates drop regno, force
		
		list regno if missing(real(regno))
		replace regno = "" if missing(real(regno)) // Set nonnumeric instances of regno as missing
		destring regno, replace
		drop if regno==. // Drop instances where regno is missing.
		
			
		destring subno, replace
		bysort regno: egen subsidiaries = max(subno)
		list regno subno subsidiaries in 1/1000
		
		keep if subno==0
		/*
			Think about keeping subsidiaries later on, as we can track their registration and removal dates.
		*/
	
	
	/* Remove unnecessary variables */
	
	drop add1 add2 add3 add4 add5 phone fax
	codebook corr // Looks like the name of the principal contact; drop.
	drop corr
	
		
	/* 	Sort data */
	
	sort regno
	list regno in 1/1000
	notes: use regno for linking with other datasets containing charity numbers

	
	/* Invalid values for each variable */
		
	codebook name
	list name in 1/1000 // There are some dummy charities (e.g. TestCharity, DELETED) that need to be removed.
	preserve
		gsort name
		list name in 1/1000
	restore
	/*
		There are some minor issues with name (invalid values e.g. TestCharity, DELETED).
		I'll just assume that all of the values for regno are valid and ignore this variable.
	*/
	
	
	codebook subno // Is a constant i.e. no subsidiary orgs in the dataset; drop
	drop subno
	
	
	codebook orgtype
	tab orgtype // RM=removed, R=registered i.e. active
	encode orgtype, gen(charitystatus)
	tab charitystatus
	recode charitystatus 1=1 2=2 3/max=. // Recode anything above 2 (the highest valid value) as missing data.
	label define charitystatus_label 1 "Registered" 2 "Removed"
	label values charitystatus charitystatus_label
	tab charitystatus
	drop orgtype
	
	
	codebook aob aob_defined // Both are free-text fields that we can do nothing with at this moment; drop.
	drop aob aob_defined 
	
	
	codebook gd // Statement from governing document; keep.

	
	codebook nhs
	tab nhs // Should have two values: T=true, F=false. Only has false, missing and incorrect string values.
	drop nhs

	
	codebook ha_no
	drop ha_no // Should be a charity's Housing Association number; only contains the value "F", the rest is missing; drop.
	
	
sav $path1\ew-charityregister-`fdate'.dta, replace	


/* extract_financial dataset */

import delimited using $path2\ew\extract_financial.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
label data "Financial history for a main registered charity"
**codebook *, problems

	duplicates report // No duplicate records for all variables.
	duplicates report regno 
	duplicates report regno fyend
	duplicates drop regno fyend, force
		
	
	/* 	Sort data */
	
	sort regno fyend
	list regno fyend in 1/1000
	
	
	/* Invalid values for each variable */
	
	drop if income==. | expend==. | income < 0
	
	codebook regno
	inspect regno // This variable is a string; should really be numeric.
	notes: Use regno for linking with other datasets containing charity numbers
	drop if regno==.
	
	
	codebook fyend
	sort fyend
	list fyend in 1/1000
	** Missing values **
	
	mdesc
		
	
	gen year = substr(fyend, 1, 4)
	destring year, replace
	
	
	capture drop orgsize
	gen orgsize = income
	recode orgsize min/9999=1 10000/99999=2 100000/999999=3 1000000/9999999=4 10000000/99999999=5 100000000/max=6 *=.
	label define orgsize_lab 1 "Under £10k" 2 "£10k-£100k" 3 "£100k-£1m" 4 "£1m-£10m" 5 "£10m-£100m" 6 "Over £100m" 
	label values orgsize orgsize_lab
	tab orgsize

	
	duplicates report regno year
	duplicates list regno year
	duplicates drop regno year, force // Come back to this issue; most likely caused by charities changing their fyend date in the same calendar year.
		

	codebook income expend
	inspect income expend
	sum income expend, detail
	
	foreach var in income expend {
		replace `var' = round(`var', 1)
	}

	**ladder income exp
	
		count if income==0 // 80,351 missing values for income
		count if expend==0 // 182,430 missing values for expenditure
			
		foreach var in income expend {
			gen ln_`var' = ln(`var' + 1)
			histogram ln_`var', normal freq
		}
		sum ln_income ln_expend, detail
		/*
			Need to do something with these zeroes: exclude them from analyses? I suppose they are fine for now.
			
			Both income and expenditure are normally distributed if you discount zeroes.
		*/

		
		
		
	/* 3. Set data as panel format */
	
	xtdes, i(regno) t(year) patterns(20) 
		notes: We have multiple years of observations for 157,395 unique charities for 14 years.
	isid regno year
	xtset regno year
	
	xttab year

		// Create variable capturing latest annual return year; can be used to calculate charity age (later on)
	
		by regno: egen latest_repyr = max(year)
		xttab latest_repyr // Can be cross referenced with yearremoved to see what year a charity 'failed'.
		tab year latest_repyr
		
		**gen charityage = maxyear - yearregistered
		**tab charityage
		
		// Create variables to capture whether a charity made a surplus or a loss:
		
		capture drop incexpdiff
		gen incexpdiff = income - expend // Check what effect (if any) missing data has on this calculation.
			count if income==. & expend==.
			count if income==. | expend==. // 129,034 instances where either inc or exp have missing values.
		codebook incexpdiff
		inspect incexpdiff
		sum incexpdiff
		tabstat incexpdiff, s(n range mean median sd max min sum p25 p75 iqr) format(%9.0f)

		capture drop surplus
		gen surplus = 1 if incexpdiff > 0
		tab surplus
		recode surplus 1=1 *=0
		tab surplus
		
		capture drop loss
		gen loss = 1 if incexpdiff<0
		tab loss
		recode loss 1=1 *=0
		tab loss

		capture drop breakeven
		gen breakeven = incexpdiff if incexpdiff==0
		recode breakeven 0=1 *=0
		tab breakeven
	
		// Quick look to see if these variables were created properly:
		list regno surplus loss breakeven in 1/100

	
	label variable regno "Charity number of organisation"
	label variable year "Financial year end"
	label variable income "Annual gross income - validated"
	label variable expend "Annual gross expenditure - validated"
	label variable latest_repyr "Most recent reporting year - derived from year"
	label variable charitysize "Categorical measure of charity income - derived from inc"
	label variable charitysize_exp "Categorical measure of charity income - derived from exp"
	label variable surplus "Charity made a surplus between (not necessarily consecutive) years"
	label variable loss "Charity made a loss between (not necessarily consecutive) years"
	label variable breakeven "Charity broke even between (not necessarily consecutive) years"

	notes: Dataset contains observations from 2003 - 2017 inclusive.

sav $path1\ew-financialhistory-`fdate'.dta, replace	
	
	
/* Charitable purposes classification dataset */

import delimited using $path2\ew\extract_class.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
	
	duplicates report
	duplicates list
	
	duplicates report regno // Huge number of duplicate charity numbers, which is probably accounted for by a charity having more than one purpose.

	codebook regno
	list regno in 1/1000
	notes: use regno for linking with other datasets containing charity numbers

	codebook class
	tab class
	rename class classno // To match the class reference dataset
	
	sort classno
	
sav $path1\ew_class_may2018_v1.dta, replace


/* Charitable purposes classification reference dataset */

import delimited using $path2\extract_class_ref.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
	
	duplicates report
	duplicates list
	
	codebook classno
	sort classno
	
	codebook classtext
	tab classtext
	
sav $path1\ew_class_ref_may2018.dta, replace

	
/* extract_main_charity dataset */

import delimited using $path2\extract_main_charity.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
label data "One observation for every main registered charity (no subsidiaries)"
**codebook *, problems

/*
		- remove problematic variables/cases e.g. duplicate records, missing values etc
		- sort data by unique identifier
		- explore invalid values for each variable
		- label variables/values/dataset
*/


	/* Missing or duplicate values */
	
	capture ssc install mdesc
	mdesc
	missings dropvars, force
	
	duplicates report
	duplicates list
	duplicates drop
	
	duplicates report regno
	duplicates list regno
	
	
	/* Remove unnecessary variables */
	
	drop email web
	
		
	/* 	Sort data */
	
	sort regno
	list regno in 1/1000
	notes: use regno for linking with other datasets containing charity numbers

	
	/* Invalid values for each variable */
		
	codebook coyno // Companies House number
	list coyno if ~missing(real(coyno)) in 1/1000
	list coyno if regex(coyno, "OC")
	replace coyno = "" if missing(real(coyno)) // Set nonnumeric instances (including blanks) of coyno as missing
	
		capture drop length_coyno
		gen length_coyno = strlen(coyno)
		tab length_coyno // 0=missing and lots of varying lengths.
		drop length_coyno
		
	destring coyno, replace
	
	duplicates report regno coyno
	
	gen company = 1 if coyno!=. 
	recode company 1=1 .=0
	tab company
	/*
		It's difficult to trust this field as we do not know if the company numbers themselves are valid e.g. they are of varying length.
	*/

	
	codebook trustees
	tab trustees
	encode trustees, gen(trustee_incorp)
	tab trustee_incorp
	recode trustee_incorp 1=1 2=2 3/max=. // Recode anything above 2 (the highest valid value) as missing data.
	label define trustee_incorp_label 1 "False" 2 "True"
	label values trustee_incorp trustee_incorp_label
	tab trustee_incorp
	drop trustees
	
	
	codebook welsh // Captures whether the Commission communicates with the charity via Welsh language; drop.
	drop welsh
	
	
	codebook fyend // Financial year end - DD/MM. Keep for now but it is probably not needed.
	
	
	codebook incomedate // Date latest income figure refers to- currently a string.
	rename incomedate str_incomedate
	replace str_incomedate = substr(str_incomedate, 1, 10) // Capture first 10 characters of string.
	replace str_incomedate = subinstr(str_incomedate, "-", "", .)
	tab str_incomedate, sort
	
	gen incomedate = date(str_incomedate, "YMD")
	format incomedate %td
	codebook incomedate
	
	gen incomeyr = year(incomedate) // Identify the year the latest gross income refers to
	tab incomeyr
	drop str_incomedate
	
	
	codebook grouptype // No explanation in the data dictionary as to what this represents; drop.
	drop grouptype
	
	
	codebook income
	inspect income
	sum income, detail
	
	sort regno
	
sav $path1\ew_mcdataset_may2018_v1.dta, replace	
	
	



/* extract_remove_ref dataset */	

import delimited using $path2\ew\extract_remove_ref.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact

	duplicates report
	duplicates list
	
	list , clean

	rename code remcode
	
	sort remcode
	
sav $path1\ew-rem-ref-`fdate'.dta, replace


/* extract_trustee dataset */

import delimited using $path2\extract_trustee.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact

	/* Missing or duplicate values */
	
	capture ssc install mdesc
	mdesc
	missings dropvars, force
	tab v3
	drop v3
	
	duplicates report
	duplicates list
	duplicates drop
	
	codebook regno
	sort regno
	
	codebook trustee
	list trustee in 1/1000 // We don't need the names, just a count of trustees per charity.
	bysort regno: egen trustees = count(trustee)
	sum trustees
	
	drop trustee
	
	sort regno
	list in 1/500
	duplicates report regno
	duplicates drop regno, force

sav $path1\ew_trustees_may1018.dta, replace


/* extract_acct_submit dataset */

import delimited using $path2\extract_acct_submit.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact

	/* Missing or duplicate values */
	
	capture ssc install mdesc
	mdesc
	missings dropvars, force
	
	duplicates report
	duplicates list
	duplicates drop
	
	duplicates report regno
	duplicates list regno
	
	duplicates report regno fyend
	
		
	duplicates report regno submit_date
	duplicates list regno submit_date // I cannot see why a charity should submit more than one set of accounts on the same day.
	duplicates tag regno submit_date, gen(dupregnosubdate)
	
		duplicates report regno submit_date arno
		duplicates list regno submit_date arno

	notes: use regno for linking with other datasets containing charity numbers

	
	codebook submit_date // Variables are currently strings, need to extract info in YYYYMMDD format.
	foreach var of varlist submit_date {
		rename `var' str_`var'
		replace str_`var' = substr(str_`var', 1, 10) // Capture first 10 characters of string.
		replace str_`var' = subinstr(str_`var', "-", "", .) // Remove hyphen from date information.
		
		gen `var' = date(str_`var', "YMD")
		format `var' %td
		codebook `var'
		
		gen `var'yr = year(`var')
		drop str_`var'
	}
	
	rename submit_dateyr arsubyr
	tab arsubyr
	
	
	codebook arno // Annual return mailing cycle code; not sure what we can do with this information; drop.
	drop arno
	
	
	codebook fyend
	tab fyend
	drop fyend // We can get this field in other datasets; drop.
	
	sort regno arsubyr
	
sav $path1\ew_acctsub_may2018_v1.dta, replace


/* extract_aoo_ref dataset */

import delimited using $path2\ew\extract_aoo_ref.csv, varnames(1) clear
count
desc, f
notes
codebook *, compact
	
	duplicates report
	duplicates list
	
	duplicates report aooname
	duplicates list aooname
	list if aooname=="ANTARCTICA" // Antartica is listed as a country and continent; drop observation which refers to it as a country.
	drop if aooname=="ANTARCTICA" & aootype=="D"

	notes: use aootype and aookey for linking with other datasets area of operation data
	
	
	codebook welsh // I think it identifies Welsh charities.
	tab welsh
	rename welsh str_welsh
	encode str_welsh, gen(welsh)
	tab welsh
	drop str_welsh
	
	
	tab1 aootype aookey
	
	sort aootype aookey
	
sav $path1\ew-aoo-ref-`fdate'.dta, replace


/* extract_charity_aoo dataset */

import delimited using $path2\ew\extract_charity_aoo.csv, varnames(1) clear // Information on a charity's area of operation.
count
desc, f
notes
codebook *, compact
**codebook *, problems

/*
		- remove problematic variables/cases e.g. duplicate records, missing values etc
		- sort data by unique identifier
		- explore invalid values for each variable
		- label variables/values/dataset
*/


	/* Missing or duplicate values */
	
	capture ssc install mdesc
	mdesc
	missings dropvars, force
	
	duplicates report
	duplicates list
	duplicates drop
	
	duplicates report regno
	duplicates list regno // Duplicates probably due to inclusion of subsidiaries in this dataset.
		
		
	/* 	Sort data */
	
	sort regno
	list regno in 1/1000
	notes: use regno for linking with other datasets containing charity numbers

	
	/* Invalid values for each variable */
		
	codebook welsh // I think it identifies Welsh charities.
	tab welsh
	rename welsh str_welsh
	encode str_welsh, gen(welsh)
	tab welsh
	drop str_welsh
	
	
	codebook aootype aookey // The meaning of these variables is contained in the extract_aoo_ref dataset. Encode after matching with aoo ref dataset.
	
	sort aootype aookey
		
sav $path1\ew-aoo-`fdate'.dta, replace


	
	
/* Merge supplementary datasets with Charity Register */	

	// Prep financial history dataset
	
	use $path1\ew_financialhistory_may2018_v1.dta, clear
	desc, f 
	
	keep if year==latest_repyr
	keep regno income expend year charitysize
	
	sort regno
	
	save $path1\ew_financialhistory_merge.dta, replace
	
	// Merge class datasets
	
	use $path1\ew_class_may2018_v1.dta, clear
	
	label data "Classification details"
	
	merge m:1 classno using $path1\ew_class_ref_may2018.dta, keep(match master using)
	tab _merge
	drop _merge
	
		/*
		// Reshape to wide panel
		
		drop classno
		sort regno
		list in 1/1000
		
		bysort regno: gen obs = _n
		list in 1/1000
		
		xtset regno obs
		
		reshape wide classtext, i(regno) j(obs)
		desc, f
		
		foreach var of varlist classtext1-classtext34 {
			levelsof `var'
			tab1 `var'
		}
		/*
			I'll need to do something similar to my beneficary groups count in my PhD.
		*/
	*/
	sort regno
	
	sav $path1\ew_class_may2018.dta, replace
	
	
	// Merge aoo datasets
	
	use $path1\ew-aoo-`fdate'.dta, clear
	
	merge m:1 aootype aookey using $path1\ew-aoo-ref-`fdate'.dta, keep(match master using)
	tab _merge
	drop _merge
	
	sort aootype aookey
	
	tab aooname, sort
	
	tab aoosort, sort
	
	tab aootype, sort
	rename aootype str_aootype
	encode str_aootype, gen(aootype)
	tab aootype
	label define aootype_lab 1 "Wide" 2 "LA" 3 "GLA/met county" 4 "Country" 5 "Continent"
	label values aootype aootype_lab
	tab aootype
	drop str_aootype
	
	duplicates report regno
	duplicates drop regno, force
	
	sort regno
	
	sav $path1\ew-aoo-`fdate'.dta, replace
	
	
	// Merge rem datasets
	
	use $path1\ew-regrem-`fdate'.dta, clear
	
	merge m:1 remcode using $path1\ew-rem-ref-`fdate'.dta, keep(match master using)
	tab _merge
	drop _merge
	
	rename text removed_reason
	codebook removed_reason
	tab removed_reason
	rename removed_reason oldvar
	
	encode oldvar, gen(removed_reason)
	tab removed_reason
	tab removed_reason, nolab
	drop oldvar
	notes: Only use two categories of removed_reason to measure demise/closure: CEASED TO EXIST (3) and DOES NOT OPERATE (4).
	
	sort regno
		
	duplicates report regno
	duplicates tag regno, gen(dupregno)
	list regno regy remy if dupregno!=0
	/*
		There may be something interesting going on here: charities with the same number have different registration dates, which in many cases
		seems to be because one observation has a registration and removal year, while the other just has a registration date.
		
		Look for one of these charities online. There could be duplicates due to charities changing legal form, which I think causes a new
		charity number of be issued on the Public Register but not in this dataset.
	*/
	
	drop if dupregno!=0 & remy!=.
	drop dupregno
	count
	
		list if regno==1161889
		
	duplicates report regno	
	duplicates drop regno, force
	/*
		Revisit this issue at a later date.
	*/
	
	sav $path1\ew-regrem-`fdate'.dta, replace
	
	
	// Merge the supplementary datasets with the charity register
	
	use $path1\ew-charityregister-`fdate'.dta, clear
	
	merge 1:1 regno using $path1\ew-regrem-`fdate'.dta, keep(match master using) // Registration information
	tab _merge
	rename _merge rem_merge
	
	merge 1:1 regno using $path1\ew-aoo-`fdate'.dta, keep(match master using) // Area of operation information
	tab _merge
	rename _merge aoo_merge
	drop if aoo_merge==2
	
	merge 1:1 regno using $path1\ew_trustees_may1018.dta, keep(match master using) // Trustees information
	tab _merge
	rename _merge trustee_merge
	drop if trustee_merge==2
	
	merge 1:1 regno using $path1\ew_financialhistory_merge.dta, keep(match master using) // Latest financial information
	tab _merge
	rename _merge fin_merge
	drop if fin_merge==2
	bysort fin_merge: tab charitystatus // We didn't get any financial information for removed charities
	
	
/* Final data management */

	/* Charity age */
	
	capture drop charityage
	gen charityage = 2020 - regy if charitystatus==1
	replace charityage = remy - regy if charitystatus==2

	
	/* Create dependent variables */
	
	// Removed
	
	capture drop dereg
	gen dereg = charitystatus
	recode dereg 1=0 2=1
	tab dereg charitystatus
	label variable dereg "Organisation no longer registered as a charity"
	
	// Multinomial measure of removed reason
	/*
		Map to conceptual framework.
	*/
	
	capture drop dissolution
	gen dissolution = .
	replace dissolution = 0 if charitystatus==1
	replace dissolution = 1 if removed_reason==3 | removed_reason==4
	replace dissolution = 2 if removed_reason==2 | removed_reason==13 | removed_reason==20
	replace dissolution = 3 if removed_reason==1
	tab dissolution
	tab removed_reason dissolution
	tab dissolution charitystatus
	label define rem_label 0 "Registered" 1 "Org Death" 2 "Revocation" 3 "Rebirth"
	label values dissolution rem_label
	label variable dissolution "Indicates whether a charity has been de-registered and for what reason"


compress
		
sav $path3\ew-charityregister-analysis-`fdate'.dta, replace
	
	
	/* Empty working data folder */
	
	**shell rmdir $path1 /s /q
	
	pwd
	
	local workdir $path2
	cd `workdir'
	
	local datafiles: dir "`workdir'" files "*.dta"
	
	foreach datafile of local datafiles {
		rm `datafile'
	}
	
	
	
	
	
