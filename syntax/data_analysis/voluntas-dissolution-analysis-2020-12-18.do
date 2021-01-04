// File: 
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 18/12/2020

******* Dissolution data analysis *******

/* 
	This DO file analyses charity data for Voluntas paper:
		- time-series of deregistrations (by reason and overall)
		- cross-sectional and longitudinal predictive models
*/


/** 0. Define paths **/

global dfiles "C:\Users\t95171dm\Dropbox\voluntas-paper" // location of data files
global rfiles "C:\Users\t95171dm\projects\charity-dissolution" // location of syntax and other project outputs
global fdate : di %tdCY-N-D daily("$S_DATE", "DMY")
di "$fdate"

include "$rfiles\syntax\project-paths.doi"



********************************************************************************


********************************************************************************	


/** 1. Import data **/

** Australia **

use $path3\aus_charreg_analysis_20190910.dta, clear
count
desc, f
notes

/** 2. Descriptive analysis **/

	** Rate of dissolution over time **
	
	preserve
		gen freq=1
		keep if dissolution > 0 & statusy > 1999
		collapse (count)freq , by(statusy dissolution)
		l
		forvalues i = 1/3 {
			gen cunum`i' = log10(sum(freq)) if dissolution==`i'
			sum cunum`i'
			l
		}
		
		twoway (line cunum1 statusy, lpatt(solid)) (line cunum2 statusy, lpatt(longdash)) (line cunum3 statusy, lpatt(shortdash)) ///
			, scheme(s1mono) title("Cumulative Number of Dissolutions") subtitle("By Year and Type") ///
			xlabel(, labsize(small)) ylabel(1 "10" 2 "100" 3 "1000" 4 "10000", labsize(small)) ///
			ytitle("Number of dissolutions") xtitle("Year") ///
			legend(label(1 "Organisational Death") label(2 "Revocation") label(3 "Rebirth") rows(1) size(small)) ///
			note("Source: ACNC. Produced: $S_DATE.", size(vsmall))
		graph export $path6\voluntas-dissolution-aus-ts-`fdate'.png, replace width(4096)
	restore




** England and Wales **

use $path3\ew-dissolution-analysis.dta, clear
count
desc, f
notes

	
********************************************************************************


********************************************************************************	
	
	
/** 2. Descriptive analysis **/

	** Rate of dissolution over time **
	
	preserve
		gen freq=1
		keep if dissolution > 0 & diss_year > 1999
		collapse (count)freq , by(diss_year dissolution)
		l
		forvalues i = 1/3 {
			gen cunum`i' = log10(sum(freq)) if dissolution==`i'
			sum cunum`i'
			l
		}
		
		twoway (line cunum1 diss_year, lpatt(solid)) (line cunum2 diss_year, lpatt(longdash)) (line cunum3 diss_year, lpatt(shortdash)) ///
			, scheme(s1mono) title("Cumulative Number of Dissolutions") subtitle("By Year and Type") ///
			xlabel(, labsize(small)) ylabel(1 "10" 2 "100" 3 "1000" 4 "10000" 5 "100000", labsize(small)) ///
			ytitle("Number of dissolutions") xtitle("Year") ///
			legend(label(1 "Organisational Death") label(2 "Revocation") label(3 "Rebirth") rows(1) size(small)) ///
			note("Source: Charity Commission for England and Wales. Produced: $S_DATE.", size(vsmall))
		graph export $path6\voluntas-dissolution-ts-`fdate'.png, replace width(4096)
	restore


	
********************************************************************************


********************************************************************************	
	
	
/** 3. Statistical modelling **/
/*
	Estimate logit and multinomial regressions.
	
	Estimate on different samples:
		- all charities
		- those that have submitted an annual return
		
	Estimate linear probability models to check robustness of findings.
*/

tab1 scale icnpo_ncvo_category_num orgage_cat incorp diss_year


** Logit **

logit dissolution i.orgage_cat ib14.icnpo_ncvo_category_num ib3.scale incorp if diss_year > 1999, vce(robust)
fitstat

	// Graph coefficients

	quietly logit, coeflegend noheader // recover variable names
	#delimit ;
	coefplot, baselevels drop(_cons 14.icnpo_ncvo_category_num 0.orgage_cat 3.scale 0.incorp 1.aob) xline(0)
			  ytitle("Independent Variables" " ") xtitle(" " "Log Odds")
			  title("Regression Model of Dissolution",
			  size(medium) justification(right)) ylab(, labsize(small) nogrid) xlab(, nogrid)
			  subtitle("Binary outcome", size(medsmall) justification(right))
			  headings(10.orgage_cat = "{bf:Age}" 1.icnpo_ncvo_category_num = "{bf: Field of activity}" 1.scale = "{bf:Scale of operations}"
				incorp = "{bf:Incorporation status}")
				grid(none)
				msize(medium)
			   scheme(s1mono)
			   note("Adjusted R-Squared =.24" "* p < .05, ** p < .01, *** p < .001")
			   name(myplot, replace)
			   ;
	#delimit cr
	
	graph export $path6\voluntas-dissolution-logit-`fdate'.png, replace width(4096)


	
** Mlogit **
/*
	See Breen et al. (2018) for guidance on interpreting the coefficients from these models.
*/
	
mlogit dissolution i.orgage_cat ib14.icnpo_ncvo_category_num ib3.scale incorp if diss_year > 1999, base(0) vce(robust)
fitstat
listcoef	
	
	// Store results of -listcoef- in a matrix
	
	mat x = r(table) // store results in a matrix
	*mat li x
	/*
		See CITM syntax for how to store these results in a data set.
	*/
	
	parmest, format(estimate min95 max95 %8.2f p) list(,) saving($path3\ew_mlogit_results.dta, replace) // store parameter estimates in a data set


	// Graph coefficients
	/*
		Produce a graph for each set of variables. [DONE]
		Add confidence intervals (spike graph?).
		Common yaxes.
		Add info on significance tests for differences between outcomes.
		
	*/
	use $path3\ew_mlogit_results.dta, clear
	
	drop if eq=="Registered"
	drop if parm=="_cons"
	encode parm, gen(var)
	tab var
		
		** Orgtype variables
		
		preserve
			keep if inlist(var, 2, 7, 14, 20, 21) 
			recode var 7=3 14=4 20=5 21=6
			tab var
			tab var, nolab
			l parm estimate var eq
			count
			
			twoway (scatter estimate var if eq=="Org_Death", msymbol(circle_hollow) msize(medlarge)) ///
				(scatter estimate var if eq=="Revocation", msymbol(Th) msize(medlarge)) ///
				(scatter estimate var if eq=="Rebirth", msymbol(Dh) msize(medlarge)) ///
				, title("Regression Coefficients") subtitle("By Dissolution Type") ytitle("Log odds") xtitle("ICNPO") ///
				yline(0, lcolor(gs10)) ///
				xscale(r(1 7)) ///
				xlab(2 "Culture" 3 "Religion" 4 "Development" 5 "Grantmaker" 6 "Health", labsize(small)) ylabel(, labsize(small)) ///
				legend(label(1 "Organisational Death") label(2 "Revocation") label(3 "Rebirth") rows(1) size(small)) ///
				scheme(s1mono)
			graph export $path6\ew_mlogit_dissolution_icnpo.png, replace width(4096)	
		restore
		/*
			Add CIs like so: (rcap min95 max95 var if eq=="Failed_to_file", msize(small))
		*/
		
		** Other variables (minus controls)
		/*
			Too many variables for one graph.
		*/
		
		preserve
			keep if parm=="mndon_maj" | parm=="gov" | parm=="2.areaop" | parm=="3.areaop" | parm=="cyp" | ///
				parm=="edsec" | parm=="orgage_dum" | parm=="mninc_ln"
			tab var
			tab var, nolab
			recode var 4=1 6=2 7=3 8=4 9=5 10=6 12=7 14=8 
			
			twoway (scatter estimate var if eq=="Failed_to_file", msymbol(circle_hollow) msize(medlarge)) ///
				(scatter estimate var if eq=="Voluntary_removal", msymbol(Th) msize(medlarge)) ///
				(scatter estimate var if eq=="Wound_up", msymbol(Dh) msize(medlarge)) ///
				, title("Regression Coefficients") subtitle("By Dissolution Type") ytitle("Log odds") xtitle(" ") ///
				yline(0, lcolor(gs10)) ///
				xlab(1 "National" 2 "International" 3 "CYP" 4 "Education" 5 "Public funding" 6 "Donations" 7 "Size" 8 "Age" , labsize(vsmall)) xlabel(, labsize(small)) ///
				legend(label(1 "Failure to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
				scheme(s1mono)
			graph export $path6\nz_mlogit_dissolution_othvars.png, replace width(4096)	
		restore		
		
		** Control variables
		
		preserve
			keep if parm=="mnemptotal" | parm=="mnvoltotal" | parm=="orgtt"
			tab var
			tab var, nolab
			recode var 12=1 14=2 16=3
			
			twoway (scatter estimate var if eq=="Failed_to_file", msymbol(circle_hollow) msize(medlarge)) ///
				(scatter estimate var if eq=="Voluntary_removal", msymbol(Th) msize(medlarge)) ///
				(scatter estimate var if eq=="Wound_up", msymbol(Dh) msize(medlarge)) ///
				, title("Probability of Dissolution") subtitle("Population ecology indvars") ytitle("Log odds") xtitle(" ") ///
				yline(0, lcolor(gs10)) ///
				xsc(r(0.5 3.5)) ///
				xlab(1 "Average number of employees" 2 "Average number of volunteers" 3 "Total number of trustees", labsize(small)) ylabel(, labsize(small)) ///
				legend(label(1 "Failure to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
				scheme(s1color)
			graph export $path7\nz_mlogit_dissolution_contro.png, replace width(4096)	
		restore
