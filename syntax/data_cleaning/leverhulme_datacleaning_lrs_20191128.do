// File: leverhulme_datacleaning_lrs_20191128.do
// Creator: Diarmuid McDonnell
// Created: 28/11/2019

******* Long-run survivors - data cleaning  *******

/* This DO file produces a statistically useable dataset for analysing long-run survivors in the charity sector.
   It performs the following tasks:
		- import datasets
		- clean datasets
		- link datasets
		- create variables for analysis
		- document the results of the above
	
	Files:
		- ncvo_charitydata_analysis_20171211.dta [Register of Charities]
		- BhamChar97.dta and BhamChar82.dta [Birmingham Index]
		- 1994_CSO_data.sav [Central Statistics Office Survey]
		- foundationdates.dta and bigl_foundationdates.dta[Foundation Dates]
		- citm_case_studies_summary_analysis.dta [Accounts Data]
		
	Notes:

*/


******* Preliminaries *******

// These are all handled by profile.do

/*
clear
capture clear matrix
set mem 400m // not necessary in recent versions of Stata
set more off, perm
set scrollbufsize 2048000
exit
*/

/* Define paths */

include "C:\Users\mcdonndz-local\Desktop\github\a-tale-of-four-cities\do_files\leverhulme_paths.doi"


********************************************************************************


********************************************************************************

/* 1. Import data sets [T001] */

/* Register of Charities */

use $path3\ncvo_charitydata_analysis_20171211.dta, clear
count
desc, f
notes
	
	// Keep relevant variables
	
	keep regno name aob_classified coyno postcode area regy remy latest_repyr charitystatus removed_reason icnpo firstd bigrofo foundyear closure
	
	// Identify companies
	
	codebook coyno
	l coyno in 1/50 if ~missing(coyno)
	gen incorp = (coyno!="")
	tab incorp
	
sort regno
sav $path1\ncvo_register_of_charities_v1.dta, replace


/* Birmingham Indices */

// 1982 

import delimited $path2\BhamIndex82.csv, varnames(1) clear
count
desc, f

	// Keep relevant variables
	
	keep charityname registrationnumber yearfounded income
	rename income inc_1982
	label variable inc_1982 "Most recent annual income, recorded in 1982 Birmingham Index"
	
	// Clean up variables
	
	tab1 yearfounded registrationnumber
	
	l if missing(real(registrationnumber)) & ~missing(registrationnumber) // remove non-numeric characters from charity number
	egen regno = sieve(registrationnumber), keep(numeric) // make sure 'egenmore' is installed: ssc install egenmore
	l regno registrationnumber
	destring regno, replace
	drop registrationnumber
	
		duplicates report regno
		duplicates tag regno, gen(dupregno)
		duplicates drop regno, force
		/*
			This drops observations with missing values for regno.
		*/
	
	gen yearfounded_len = strlen(yearfounded)
	tab yearfounded_len // should be four characters long i.e. YYYY
	l regno yearfounded if yearfounded_len!=4 & yearfounded!=""
	/*
		If yearfounded_len==10, then grab last 4 characters
		If yearfounded_len==9, then set as missing
		If anything else, then set as missing
	*/
	
	gen fyear_1982 = yearfounded
	replace fyear_1982 = substr(fyear_1982, 6, .) if yearfounded_len==10
	replace fyear_1982 = "" if yearfounded_len==9 | yearfounded_len==3
	replace fyear_1982 = subinstr(fyear_1982, "/", "", .)
	destring fyear_1982, replace
	tab fyear_1982
	drop yearfounded*
	
	codebook charityname
	rename charityname name
	l name in 1/50
		
sort regno
sav $path1\bham_index_1982.dta, replace


// 1997

import delimited $path2\BhamChar97.csv, varnames(1) clear
count
desc, f

	// Keep relevant variables
	/*
		The 'comments' field contains information on whether and how a charity is inoperative or removed.
	*/
	
	keep charityname registrationnumber yearfounded income
	rename income inc_1997
	label variable inc_1997 "Most recent annual income, recorded in 1997 Birmingham Index"
	
	// Clean up variables
	
	tab1 yearfounded registrationnumber
	
	l if missing(real(registrationnumber)) & ~missing(registrationnumber) // remove non-numeric characters from charity number
	egen regno = sieve(registrationnumber), keep(numeric) // make sure 'egenmore' is installed: ssc install egenmore
	l regno registrationnumber
	destring regno, replace
	drop registrationnumber
	
		duplicates report regno
		duplicates tag regno, gen(dupregno)
		duplicates drop regno, force
		/*
			This drops observations with missing values for regno.
		*/
	
	gen yearfounded_len = strlen(yearfounded)
	tab yearfounded_len // should be four characters long i.e. YYYY
	l regno charityname yearfounded if yearfounded_len!=4 & yearfounded!=""
	/*
		If yearfounded_len==10, then grab last 4 characters (with the exception of Chance & Kendrick Scholarship Trust)
		If anything else, then set as missing
	*/
	
	gen fyear_1997 = yearfounded
	replace fyear_1997 = substr(fyear_1997, 6, .) if yearfounded_len==10 & charityname!="Chance & Kendrick Scholarship Trust"
	replace fyear_1997 = substr(fyear_1997, 1, 5) if charityname=="Chance & Kendrick Scholarship Trust"
	replace fyear_1997 = "" if yearfounded_len==9 | yearfounded_len==3 | yearfounded_len==5
	replace fyear_1997 = subinstr(fyear_1997, "/", "", .)
	destring fyear_1997, replace
	tab fyear_1997
	drop yearfounded*
	
	codebook charityname
	rename charityname name
	l name in 1/50
	replace name = upper(name) // standardise
		
sort regno
sav $path1\bham_index_1997.dta, replace


/* CSO Survey */

usespss $path2\1994_CSO_data.sav, clear
count
desc, f
notes
/*
	Nothing relevant to this study as it mainly contains financial information.
*/


/* Financial History */
/*
	Spread across two files:
		- NCVO data [FinHis8515.dta]
		- Charity Commission data [extract_financial.csv]
*/

** 1985 - 2015 finhist
/*
	Use this dataset up-to 2013.
*/

use $path2\FinHis8515.dta, clear
codebook
	
	rename inc income
	rename exp expend
	drop _merge
	
	tab year
	drop if year > 2013
	
sort regno year	
sav $path1\finhist_1985_2013.dta, replace
	
	
** extract_financial.csv (CCEW data download - Feb19)
/*
	Use this data set for 2014-17
*/

import delimited using $path2\extract_financial.csv, varnames(1) clear
desc, f
codebook *
	
	** Convert string to date **
	
	foreach var of varlist fyend fystart {
		rename `var' str_`var'
		replace str_`var' = substr(str_`var', 1, 10) // Capture first 10 characters of string.
		replace str_`var' = subinstr(str_`var', "-", "", .)
		gen `var' = date(str_`var', "YMD")
		format `var' %td
		drop str_`var'
	}
	
	gen year = year(fyend) // capture year of fyend
	gen month = month(fyend) // capture month of fyend
	tab1 year month // do not have a lot of observations for 2016 yet
	
	** Keep 2016 observations **
	
	keep if year > 2013 & year < 2018
	
	** Remove duplicates **
	
	duplicates drop regno year, force

sort regno year
sav $path1\finhist_2014_2017.dta, replace

	
** Combine files

use $path1\finhist_1985_2013.dta, clear
	
	merge 1:1 regno year using $path1\finhist_2014_2017.dta, keep(match master using)
	rename _merge fh_merge
	label define fh_merge_lab 1 "1985/2013 file" 2 "2014/2017 file" 3 "Both files"
	label values fh_merge fh_merge_lab	
	tab fh_merge // no overlap, good
	
sav $path1\finhist_1985_2017_v1.dta	, replace


** Adjust for inflation
/*
	See what David Clifford (2018) used.
*/

use $path1\finhist_1985_2017_v1.dta, clear

** Create variables

	// Count number of times charity appears in data
	
	sort regno year
	bys regno: gen numobs = _N
	bys regno: gen t = _n	
	
	
	// Fill in missing data
	/*
		For now I'm going to create a dummy indicating missing data.
		
		Consider multiple imputation.
	*/
	
	gen inc_miss = (income==.)
	tab inc_miss
	label variable inc_miss "Missing value for income"
		
	
	// Income/expenditure growth
	/*
		Annual relative growth y in headline income/expenditure x for organisation i between years t − 1 and t is given by:
			yi,t = xi, t/xi, t−1
			
		We only capture income growth if the previous year's income was at least £1k.
		See Clifford (2017) for further information on operationalising this measure.
	*/
	
	sort regno year // important that the data set is sorted in order to calculate differences between years
	capture drop *_arg
	foreach var of varlist income expend {
		bys regno: gen `var'_arg = (`var') / (`var'[_n-1]) if `var'[_n-1] >= 1000
		sum `var'_arg, detail
		l regno year `var' `var'_arg in 1/100
	}
	/*
		Looks to have worked; do a couple of manual robustness checks.
	*/

	
	// Zero-income returns
	
	count if income==0
	gen zinc = (income==0)
	bys regno: egen zinc_count = total(zinc)
	sum zinc zinc_count , detail
	l regno year income zinc zinc_count if zinc==1
	label variable zinc "Income is zero for a given annual return"
	label variable zinc_count "Total number of zero-income annual returns per charity"
	
		// Identify charities that only submitted zero-income returns
		
		gen zinc_only = (numobs==zinc_count)
		distinct regno if zinc_only
		di "`r(ndistinct)' charities have submitted only zero-income returns"
		label variable zinc_only "Charity has only submitted zero-income returns"
		
	
	// Financial vulnerability
	
	preserve
		
		// Funding and financial disruption risk: 25% or greater reduction in total revenue or total expenditure

		keep regno year income expend
		mdesc
		reshape wide income expend, i(regno) j(year)
		list in 1/100
		mdesc
		
		// Calculate the magnitude of the reduction in income
				 
		capture drop reduction*
			
		foreach var in income expend {
			local counter = 2017 // total number of years in the panel
			local lwcounter = `counter' - 1
			forvalues i = 2017(-1)1986 {
				gen reduction_`var'_`i' = `var'`counter' - `var'`lwcounter' if ~missing(`var'`counter') & ~missing(`var'`lwcounter')
				di "reduction_`var'_`i' =" _col(10) "`var'`counter' - `var'`lwcounter'"
				codebook reduction_`var'_`i', compact
				local counter = `counter' - 1
				local lwcounter = `lwcounter' - 1
			}
		}
		/*
			It appears to have worked but I need to do some robustness checks e.g. manually substract values to see if the correct figure is being
			calculated. Also test against the manual syntax (see end of file). And if it should be & or |.
		*/
		
			list income2017 income2016 reduction_income_2017 if reduction_income_2017!=. // Looks to have worked

			// Calculate the change in income relative to the previous year and convert to a percentage
			
			capture drop change*
			
			foreach var in income expend {
				local counter = 2017 // total number of years in the panel
				local lwcounter = `counter' - 1
				forvalues i = 2017(-1)1986 {
					gen change_`var'_`i' = (reduction_`var'_`counter'/`var'`lwcounter') * (100/1) if reduction_`var'_`counter' < 0 & ~missing(reduction_`var'_`counter') & ~missing(`var'`lwcounter')
					di "change_`var'_`i' =" _col(10) "reduction_`var'_`counter'/`var'`lwcounter') * (100/1)"
					codebook change_`var'_`i', compact
					local counter = `counter' - 1
					local lwcounter = `lwcounter' - 1
				}
			}	
			/*
				It appears to have worked but I need to do some robustness checks: why reduction < 0?
				Also test against the manual syntax (see end of file). And if it should be & or |.
			*/

			// Change negative changes to positive
			
			desc, f
			foreach var of varlist change_income_2017-change_expend_1986 {
				replace `var' = `var' * -1
			}
						
			inspect change*	

			
			// Finally, create dummy variables that indicates whether the change in funding was equal to or greater than a given threshold.
									
			foreach var in income expend {
				local counter = 2017 // total number of years in the panel
				local lwcounter = `counter' - 1
				forvalues i = 2017(-1)1986 {
					foreach thres in 25 50 90 100 {
						gen fr_`var'_`thres'_`i' = 1 if change_`var'_`i' >= `thres' & ~missing(change_`var'_`i')
						di "fr_`var'_`thres'_`i' = 1 if change_`var'_`i' >= `thres'"
						recode fr_`var'_`thres'_`i' 1=1 *=0 if ~missing(reduction_`var'_`i')
						codebook fr_`var'_`thres'_`i', compact
					}
				}
			}	
			
			tab1 fr_*
			
			sav $path1\leverhulme_finvul_20191129.dta, replace
			
		restore
		
		// Keep regno and fundingrisk variables and reshape
			
		foreach var in income expend {
			preserve

				use $path1\leverhulme_finvul_20191129.dta, clear
				keep regno fr_`var'_*
				
				// Reshape from wide to long
				
				reshape long fr_`var'_25_ fr_`var'_50_ fr_`var'_90_ fr_`var'_100_ , i(regno) j(year)
				desc, f
				sort regno
				tab year
				
				sav $path1\leverhulme_fr_`var'_20191129.dta, replace // Merge this file with the annual accounts data
			restore
			
			sort regno year
			count
			
			// Merge with main data set
			
			merge 1:1 regno year using $path1\leverhulme_fr_`var'_20191129.dta, keep(match master using)
			tab _merge
				tab year if _merge==1
			drop if _merge==2
			drop _merge
			
			foreach thres in 25 50 90 100 {
				rename fr_`var'_`thres'_ fr_`var'_`thres'
			}
		}
		/*
			Looks to have worked but why so many unmatched observations in the using data set?
		*/
		
	
	// Count number of vulnerabilities per charity
	
	bys regno: egen income_vul_num = total(fr_income_25)
	bys regno: egen expend_vul_num = total(fr_expend_25)
	l regno year fr_income_25 income_vul_num fr_expend_25 expend_vul_num
	label variable income_vul_num "Total number of financial vulnerability occurrences (income)"
	label variable expend_vul_num "Total number of financial vulnerability occurrences (expenditure)"
	
		// Other measures
		
		gen income_vul_dum = (income_vul_num > 0 & income_vul_num!=.) // dummy variable for charities experiencing at least 1 vulnerability
		gen income_vul_per_year = income_vul_num / numobs
		label variable income_vul_dum "Experienced financial vulnerability at least once"
		label variable income_vul_per_year "Number of financial vulnerability occurrences per year"
		
	
	// Create variable capturing latest and first annual return years; can be used to calculate charity age (later on)

	by regno: egen last_year = max(year)
	bys regno: egen first_year = min(year) // identify first year
	*xttab last_year
	tab year last_year
	label variable last_year "Most recent annual return year"
	label variable first_year "First annual report year"
	
			
	/* Set data as panel format */
		
	xtdes, i(regno) t(year) patterns(20) 
	isid regno year
	xtset regno year

	xttab year


sav $path1\finhist_1985_2017_v2.dta, replace


********************************************************************************


********************************************************************************

/* 2. Merge raw datasets [T002] */

/* Register of Charities */

use $path1\ncvo_register_of_charities_v1.dta, clear

merge 1:1 regno using $path1\bham_index_1982.dta, keep(match master)
rename _merge bham1982_merge

merge 1:1 regno using $path1\bham_index_1997.dta, keep(match master)
rename _merge bham1997_merge

sav $path1\ncvo_register_of_charities_v2.dta, replace


/* Financial History */

use $path1\finhist_1985_2017_v2.dta, clear

merge m:1 regno using $path1\ncvo_register_of_charities_v2.dta, keep(match master)
rename _merge roc_merge

sav $path1\finhist_1985_2017_v3.dta, replace


********************************************************************************


********************************************************************************


/* 3. Prepare data sets for statistical analysis [T003] */

/* Financial History */

use $path1\finhist_1985_2017_v3.dta, clear
count
desc, f
notes

	// Identify Birmingham charities
		
	gen bham = (area==1)
	count
	
	
	// Fill in panel
	/*
		We want to identify charities that have gaps in their reporting history e.g.
			filed in 2008, 2009, NOT IN 2010, 2011, 2012.
	*/
	
	tsset regno year // set as time-series format
	tsfill, full
	gen blankobs = (income==. & inc_miss!=1) // identify newly created observations
	tab year
	/*
		Every charity now has an observation for every year in the panel.
	*/
	
		// Identify charities that have gaps in their reporting history	
		
		sort regno remy
		bys regno: replace remy = remy[1] if remy==. // assign removed year to every observation
		
		sort regno first_year
		bys regno: replace first_year = first_year[1] if first_year==. // assign first year to every observation
		
		sort regno last_year
		bys regno: replace last_year = last_year[1] if last_year==. // assign last year to every observation

		sort regno year
		gen gap_year = (blankobs==1 & year > first_year & year < remy) // identify years where income is missing due to filling in the panel
		bys regno: egen gap_year_count = total(gap_year)
		gen gap_year_dum = (gap_year_count > 0 & gap_year_count!=.)
		l regno year charitystatus remy income inc_miss blankobs first_year gap_year gap_year_count in 1/5000
		label variable gap_year "Year where charity failed to submit an annual return"
		label variable gap_year_count "Total number of years where harity failed to submit an annual return"
		label variable gap_year_dum "Failed to submit at least one annual return"
		
		// Drop observations that were created by `tsfill, full' command
		
		drop if blankobs
			
		// Set as panel data again
		
		xtdes, i(regno) t(year) patterns(20) 
		isid regno year
		xtset regno year


	// Cut panel
	/*
		We have very few observations for years prior to 1997. We can start the panel at 1993.
	*/
	
	tab year
	keep if year > 1992
	

	// Create dissolution variables
	/*
		Consider creating additional categories (e.g. amalgamations).
	*/
	
	gen deregistered = (charitystatus==2)
	tab deregistered
	
	tab removed_reason
	gen orgdiss = .
	replace orgdiss = 0 if charitystatus==1
	replace orgdiss = 1 if removed_reason==20 // voluntary removal
	replace orgdiss = 2 if removed_reason==3 | removed_reason==11 // ceased to exist and does not operate
	replace orgdiss = 3 if orgdiss==. & (removed_reason!=3 | removed_reason==11 | removed_reason==20) // ceased to exist and does not operate
	tab orgdiss charitystatus
	label define orgdiss_lab 0 "Registered" 1 "Voluntary removal" 2 "Wound up" 3 "Other reason"
	label values orgdiss orgdiss_lab
	label variable orgdiss "Dissolution status of charity"


	/* Create foundation year variable */
	/*
		Priority is as follows:
			- Birmingham Index 1982
			- Birmingham Index 1997
			- Big Lottery foundation date [`bigrofo']
			- Governing Document foundation date [`firstd']
			- Charity Commission registration date [`regy']
	*/
	
	gen fyear = .
	replace fyear = fyear_1982
	replace fyear = fyear_1997 if fyear==.
	replace fyear = bigrofo if fyear==.
	replace fyear = firstd if fyear==.
	replace fyear = regy if fyear==.
	tab fyear
	label variable fyear "Year organisation was founded"
	
		// Create periodisation
		
		gen period = fyear
		recode period min/1918=1 1919/1945=2 1946/1965=3 1966/1978=4 1979/1992=5 1993/max=6 *=.
		label define period_lab 1 "Pre 1918" 2 "1919-1945" 3 "1946-1965" 4 "1966-1978" 5 "1979-1992" 6 "Post 1992"
		label values period period_lab
		tab period, miss
		label variable period "Era organisation was founded"
	
	
	/* Charity age */
	/*
		If registered, then latest reporting year - fyear.
		If deregistered, then remy - fyear.
	*/
	
	gen orgage = .
	replace orgage = last_year - fyear if charitystatus==1
	replace orgage = remy - fyear if charitystatus==2
	hist orgage, scheme(s1mono) norm freq
	sum orgage
	label variable orgage "Age of organisation (in years)"
	
	
	/* Field of activity */
	
	tab icnpo, nolab sort
	gen field = .
	replace field = 1 if icnpo==14
	replace field = 2 if icnpo==17
	replace field = 3 if icnpo==2
	replace field = 4 if icnpo==1
	replace field = 5 if field==. & (icnpo!=14 | icnpo==17 | icnpo==2 | icnpo==1)
	tab icnpo field
	label define field_lab 1 "Religion" 2 "Social Services" 3 "Development" 4 "Culture and Recreation" 5 "Other"
	label values field field_lab
	
	
	/* Area of benefit */
	
	capture drop aob
	encode aob_classified, gen(aob)
	recode aob 1=1 2=2 3/4=3
	tab aob
	label define aob_lab 1 "Local" 2 "National" 3 "Overseas"
	label values aob aob_lab
	label variable aob "Area of benefit - local, national or overseas"
	
	
	/* Incorporation status */
	
	tab incorp
	label variable incorp "Organisation is incorporated"
	
	
sav $path3\leverhulme_lrs_finhist_analysis.dta, replace



	

/* Register of Charities */

use $path1\ncvo_register_of_charities_v2.dta, clear
count
desc, f
notes

	// Identify Birmingham charities
		
	gen bham = (area==1)
	count
	tab removed_reason
	
	
	// Add variables from financial history dataset
	
	preserve
		use $path3\leverhulme_lrs_finhist_analysis.dta, clear
		keep regno numobs zinc_count zinc_only income_vul_dum income_vul_per_year gap_year_count gap_year_dum
		egen pickone = tag(regno)
		keep if pickone
		sort regno
		sav $path1\leverhulme_lrs_finhist_merge.dta, replace
	restore
	
	sort regno
	merge 1:1 regno using $path1\leverhulme_lrs_finhist_merge.dta, keep(match master)
	rename _merge fh_merge
	
		// Examine unmatched charities
		/*
			These should represent organisations that never submitted an annual return.
		*/

		tab charitystatus fh_merge // vast majority have been removed from the Register
		tab remy fh_merge if fh_merge==1 // large number between 1991 and 1997 (changes to Charities Act 1992, 1993)

	
	/* Create dissolution variables */
	/*
		Consider creating additional categories (e.g. amalgamations).
	*/
	
	gen deregistered = (charitystatus==2)
	tab deregistered
	
	tab removed_reason
	gen orgdiss = .
	replace orgdiss = 0 if charitystatus==1
	replace orgdiss = 1 if removed_reason==20 // voluntary removal
	replace orgdiss = 2 if removed_reason==3 | removed_reason==11 // ceased to exist and does not operate
	replace orgdiss = 3 if orgdiss==. & (removed_reason!=3 | removed_reason==11 | removed_reason==20) // ceased to exist and does not operate
	tab orgdiss charitystatus
	label define orgdiss_lab 0 "Registered" 1 "Voluntary removal" 2 "Wound up" 3 "Other reason"
	label values orgdiss orgdiss_lab
	label variable orgdiss "Dissolution status of charity"


	/* Create foundation year variable */
	/*
		Priority is as follows:
			- Birmingham Index 1982
			- Birmingham Index 1997
			- Big Lottery foundation date [`bigrofo']
			- Governing Document foundation date [`firstd']
			- Charity Commission registration date [`regy']
	*/
	
	gen fyear = .
	replace fyear = fyear_1982
	replace fyear = fyear_1997 if fyear==.
	replace fyear = bigrofo if fyear==.
	replace fyear = firstd if fyear==.
	replace fyear = regy if fyear==.
	tab fyear
	label variable fyear "Year organisation was founded"
	
		// Create periodisation
		
		gen period = fyear
		recode period min/1918=1 1919/1945=2 1946/1965=3 1966/1978=4 1979/1992=5 1993/max=6 *=.
		label define period_lab 1 "Pre 1918" 2 "1919-1945" 3 "1946-1965" 4 "1966-1978" 5 "1979-1992" 6 "Post 1992"
		label values period period_lab
		tab period, miss
		label variable period "Era organisation was founded"
	
	
	/* Charity age */
	/*
		If registered, then latest reporting year - fyear.
		If deregistered, then remy - fyear.
	*/
	
	rename latest_repyr last_year
	gen orgage = .
	replace orgage = last_year - fyear if charitystatus==1
	replace orgage = remy - fyear if charitystatus==2
	hist orgage, scheme(s1mono) norm freq
	sum orgage
	label variable orgage "Age of organisation (in years)"
	
	
	/* Field of activity */
	
	tab icnpo, nolab sort
	gen field = .
	replace field = 1 if icnpo==14
	replace field = 2 if icnpo==17
	replace field = 3 if icnpo==2
	replace field = 4 if icnpo==1
	replace field = 5 if field==. & (icnpo!=14 | icnpo==17 | icnpo==2 | icnpo==1)
	tab icnpo field
	label define field_lab 1 "Religion" 2 "Social Services" 3 "Development" 4 "Culture and Recreation" 5 "Other"
	label values field field_lab
	
	
	/* Area of benefit */
	
	capture drop aob
	encode aob_classified, gen(aob)
	recode aob 1=1 2=2 3/4=3
	tab aob
	label define aob_lab 1 "Local" 2 "National" 3 "Overseas"
	label values aob aob_lab
	label variable aob "Area of benefit - local, national or overseas"
	
	
	/* Incorporation status */
	
	tab incorp
	label variable incorp "Organisation is incorporated"
	
	
sort regno
sav $path3\leverhulme_lrs_mlogit_analysis.dta, replace
	
	


********************************************************************************


********************************************************************************

	
	
	/* Empty working data folder */
	
	**shell rmdir $path1 /s /q
	
	pwd
	
	local workdir "C:\Users\mcdonndz-local\Desktop\data\a-tale-of-four-cities\data_working\"
	cd `workdir'
	
	local datafiles: dir "`workdir'" files "*.dta"
	
	foreach datafile of local datafiles {
		rm `datafile'
	}	
