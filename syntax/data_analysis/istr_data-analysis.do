// File: istr_data-analysis.do
// Creator: Diarmuid McDonnell
// Created: 25/04/2018

******* Charity Removal - Cross-national comparisons *******

/* 
	
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

include "C:\Users\mcdonndz-local\Desktop\github\paper-istr-2018\syntax\project_paths.doi"
di "$path1"
di "$path2"
di "$path3"
di "$path4"
di "$path5"
di "$path6"
di "$path7"
di "$path8"


/* Empty figures folder */
/*
	
	**shell rmdir $path1 /s /q
	
	pwd
	
	local workdir "C:\Users\mcdonndz-local\Desktop\github\a-tale-of-four-cities\figures\"
	cd `workdir'
	
	local datafiles: dir "`workdir'" files "*.gph"
	
	foreach datafile of local datafiles {
		rm `datafile'
	}
	
	local datafiles: dir "`workdir'" files "*.png"
	
	foreach datafile of local datafiles {
		rm `datafile'
	}

*/

/* 1. Open the clean datasets */

capture log close
**log using $path9\rqone_`tdate'.log, text replace


/* Canada */

use $path3\canada_register_20180522.dta, clear	
desc, f
count
notes
label data "Register of all Canadian charities - 20180522"

	
	// Descriptive statistics
	
	tab1 sector charitytype area
	tab depvar
	tab remy depvar if remy>=2007 // Produce a table
	
	local fdate = "01jun2018"

	graph bar , over(depvar) over(sector) stack asyvar percent ylabel(, nogrid labsize(small))
	graph bar , over(depvar) over(charitytype) stack asyvar percent ylabel(, nogrid labsize(small))
	graph bar , over(depvar) over(area) stack asyvar percent ylabel(, nogrid labsize(small))
	
	tab statyear depvar if statyear>=2007
	local numobs:di %6.0fc r(N)
	
	tab depvar if depvar>0 & statyear>=2007 // 62.5% is the average number of vol removals in a given year.
		
	graph bar if statyear>=2007 & depvar!=0, over(depvar) over(statyear) stack asyvar percent ///
		bar(1, color(maroon )) bar(2, color(dknavy)) bar(3, color(erose)) ///
		ylabel(, nogrid labsize(small)) ///
		ytitle("% of charities", size(medsmall)) ///
		yline(37, lpatt(dash) lcolor(gs8)) ///
		title("Charity Removal Reasons - Canada")  ///
		subtitle("by deregistration year")  ///
		note("Source: Canada Revenue Agency (22/05/2018);  n=`numobs'. Produced: $S_DATE.", size(vsmall) span) ///
		scheme(s1color)

	graph export $path6\can_removedreason_`fdate'.png, replace width(4096)


	**bysort depvar: sum revenue
	**bysort depvar: sum expenditure
		
			
	/* Bivariate associations between dependent and each independent variable */
		
	foreach var of varlist sector charitytype area {
		tab `var' depvar, col nofreq all
	}
	/*
		No associations!
	*/
		
	
	/* Model building */
	
	/*
		Test a number of different estimators: linear, logit, glm.
	*/
	
	// Decide on reference categories
	
	tab1 sector charitytype area
	/*
		sector==4, charitytype==3, area==1.
		
		For all three variables the most common category was chosen as the reference category.
	*/
	
	// Model 1 - null model
		
	mlogit depvar
	est store null
		
	// Model 2 - main effects
			
	regress depvar ib4.sector ib3.charitytype ib1.area, robust
	est store linr
	fitstat
			
	tab depvar
	
	mlogit depvar ib4.sector ib3.charitytype ib1.area, vce(robust) nolog rrr
	est store logr
	fitstat
	ereturn list
	
	
/* England & Wales */

use $path3\ew_charityregister_20180522.dta, clear // Data downloaded from Charity Commission data portal
desc, f
count
notes
label data "Register of all England & Wales charities - 20180522"

	
	// Descriptive statistics
	
	tab1 charitysize aootype
	tab depvar
	tab remy depvar if remy>=2007 // Produce a table
	/*
		What's going in 2009 with Other Removal?
	*/	
	
		tab removed_reason if remy==2007
		tab removed_reason if remy==2008
		tab removed_reason if remy==2009 // Accounted for by the large spike in voluntary deregistrations
	
	local fdate = "01jun2018"

	graph bar , over(depvar) over(charitysize) stack asyvar percent ylabel(, nogrid labsize(small))
	graph bar , over(depvar) over(aootype) stack asyvar percent ylabel(, nogrid labsize(small))
	
	tab remy depvar if remy>=2007
	local numobs:di %6.0fc r(N)
	
	tab depvar if depvar>0 & remy>=2007 // 50% is the average number of vol removals in a given year.
		
	graph bar if remy>=2007 & depvar!=0, over(depvar) over(remy) stack asyvar percent ///
		bar(1, color(dknavy )) bar(2, color(erose)) ///
		ylabel(, nogrid labsize(small)) ///
		ytitle("% of charities", size(medsmall)) ///
		yline(50, lpatt(dash) lcolor(gs8)) ///
		title("Charity Removal Reasons - UK")  ///
		subtitle("by deregistration year")  ///
		note("Source: Charity Commission for England & Wales (22/05/2018);  n=`numobs'. Produced: $S_DATE.", size(vsmall) span) ///
		scheme(s1color)

	graph export $path6\ew_removedreason_`fdate'.png, replace width(4096)


	**bysort depvar: sum revenue
	**bysort depvar: sum expenditure
		
			
	/* Bivariate associations between dependent and each independent variable */
		
	foreach var of varlist charitysize aootype {
		tab `var' depvar, col nofreq all
	}
	/*
		No associations!
	*/
		
	
	/* Model building */
	
	/*
		Test a number of different estimators: linear, logit, glm.
	*/
	
	// Decide on reference categories
	
	tab1 charitysize aootype
	/*
		charitysize==2, aootype==2.
		
		For all three variables the most common category was chosen as the reference category.
	*/
	
	// Model 1 - null model
		
	mlogit depvar
	est store null
		
	// Model 2 - main effects
			
	regress depvar ib2.aootype charityage, robust
	est store linr
	fitstat
			
	tab depvar
	
	mlogit depvar ib2.aootype charityage, vce(robust) nolog rrr
	est store logr
	fitstat
	ereturn list

	
	
		/* Alternative source of data - NCVO Register of Charities */
		
		use $path3\ncvo_charitydata_analysis_20171211.dta, clear
		capture datasignature report
		count
		desc, f
		notes
		
		/* Create dependent variables */

		// Removed
		
		capture drop dereg
		gen dereg = charitystatus
		recode dereg 1=0 2=1
		tab dereg charitystatus
		label variable dereg "Organisation no longer registered as a charity"
		
		// Multinomial measure of removed reason
		
		capture drop depvar
		gen depvar = .
		replace depvar = 0 if charitystatus==1
		replace depvar = 1 if removed_reason==3 | removed_reason==11
		replace depvar = 2 if removed_reason!=3 & removed_reason!=11 & removed_reason!=.
		tab depvar
		tab removed_reason depvar
		tab depvar charitystatus
		label define rem_label 0 "Active" 1 "Vol Removal" 2 "Other Removal"
		label values depvar rem_label
		label variable depvar "Indicates whether a charity has been de-registered and for what reason"

		/* Create independent variables */
		
		// Company legal form
		
		capture drop company
		list coyno if coyno!="" in 1/1000
		**destring coyno, replace
		gen company = (coyno!="")
		tab company
		/*
			coyno needs a lot more work: i.e. check for duplicates, non-numeric characters, same as regno etc.
		*/
		
		codebook icnpo_ncvo_category company period aob_classified charityage charitysize, compact
		tab icnpo_ncvo_category, nolab
		encode aob_classified, gen(areaop)
		recode areaop 3 4=3
		tab areaop

		tab remy depvar if remy>=2007
		local numobs:di %6.0fc r(N)
		
		tab depvar if depvar>0 & remy>=2007 // 50% is the average number of vol removals in a given year.
		
		local fdate = "22may2018"

		graph bar if remy>=2007 & depvar!=0, over(depvar) over(remy) stack asyvar percent ///
			bar(1, color(maroon )) bar(2, color(dknavy)) bar(3, color(erose)) ///
			ylabel(, nogrid labsize(small)) ///
			ytitle("% of charities", size(medsmall)) ///
			yline(71, lpatt(dash) lcolor(gs8)) ///
			title("Charity Removal Reasons - UK")  ///
			subtitle("by removal year")  ///
			note("Source: Charity Commission for England & Wales (31/12/2016);  n=`numobs'. Produced: $S_DATE.", size(vsmall) span) ///
			scheme(s1color)

		graph export $path6\ew_removedreason_alt_`fdate'.png, replace width(4096)
		
			
		/* Model building */
	
		/*
			Test a number of different estimators: linear, logit, glm.
		*/
		
		// Decide on reference categories
		
		**tab1 charitysize aootype
		/*
			charitysize==2, aootype==2.
			
			For all three variables the most common category was chosen as the reference category.
		*/
		
		// Model 1 - null model
			
		mlogit depvar
		est store null
			
		// Model 2 - main effects
				
		regress depvar ib17.icnpo i.company ib1.areaop ib2.charitysize charityage, robust
		est store linr
		fitstat
				
		tab depvar
		
		mlogit depvar ib17.icnpo i.company ib1.areaop ib2.charitysize charityage, vce(robust) nolog rrr
		est store logr
		fitstat
		ereturn list

