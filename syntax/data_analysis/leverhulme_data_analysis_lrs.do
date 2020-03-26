// File: leverhulme_data_analysis_lrs.do
// Creator: Diarmuid McDonnell
// Created: 28/11/2019

******* Dissolution data analysis *******

/* 
	This DO file analyses data on England and Wales charities:
		- time-series of deregistrations (by reason and overall)
		- cross-sectional and longitudinal predictive models
		
	Files:
		- leverhulme_lrs_mlogit_analysis.dta [Cross-section - Register of Charities]
		
	Samples:
		- England and Wales
		- Birmingham only
		
	Need to estimate separate models due to inability to use if qualifier with `markout'.	
		
	Notes:	
*/


/** 0. Define paths **/

include "C:\Users\mcdonndz-local\Desktop\github\a-tale-of-four-cities\do_files\leverhulme_paths.doi"


********************************************************************************


********************************************************************************	


/** 1. Import data **/

** Charity Register **

use $path3\leverhulme_lrs_mlogit_analysis.dta, clear
count
desc, f
notes
global fdate "20191202"

	
********************************************************************************


********************************************************************************	
	
	
/** 2. Descriptive analysis **/

/* Create independent variables */
/*
	Theoretical model being tested:
	
		- Population ecology:
			* Size
			* Age
			* Sector
			* Density (by sector or area)
		- New institutionalism (not sure we have measures of these):
			* Legitmacy (could be government funding; links with other charities e.g. through trustees)
			* Conformance to codes/rule etc
		- Resource dependence (see Lu et al. 2019 for operationalisations):
			* Donative vs commercial
			* Main source of funds (e.g. public funding)
			* Revenue diversification
		- Controls:
			* Year (active, not registered as this is captured in age)
			* Board size
			* Area of operation
			* Number of staff/volunteers
			
	Need to revisit notes from Hager (1999) about other factors and perspectives.		
*/

	// Describe variables
	
	codebook period field incorp aob zinc_only income_vul_dum gap_year_dum
	tab1 period field incorp aob zinc_only income_vul_dum gap_year_dum


/* Create samples based on no missing data for independent variables */

// Full sample

mdesc period field incorp aob zinc_only income_vul_dum gap_year_dum
mark nomiss
tab nomiss
markout nomiss period field incorp aob zinc_only income_vul_dum gap_year_dum
tab nomiss
label variable nomiss "Identifies observations with no missing values for independent variables"

	
/* Sample summary statistics */
/*
	Produce a paragraph and table summarising the characteristics of the sample across categories of our outcomes:
		- `deregistered'
		- `orgdiss'
	
	The independent variables to describe are:
		- period field incorp aob
		
	Every descriptive analysis should be accompanied by the following conditions: "if nomiss" and "if nomiss_bham". This restricts the sample
	to the observations included in our statistical models and for certain geographies.
		
	See example below.	
*/


	// Bivariate associations
	
	foreach var in period field incorp aob zinc_only income_vul_dum gap_year_dum {
		tab `var' deregistered if nomiss, col all
		tab `var' orgdiss if nomiss, col all
	}
	

	// Dependent variables

	tab1 deregistered orgdiss if nomiss


	// Rate of dissolution over time
	
	preserve
		gen freq=1
		keep if orgdiss > 0 & nomiss
		collapse (count)freq , by(remy orgdiss)
		
		forvalues i = 1/3 {
			gen cunum`i' = sum(freq) if orgdiss==`i'
			sum cunum`i'
		}
		
		twoway (line cunum1 remy, lpatt(solid)) (line cunum2 remy, lpatt(longdash)) (line cunum3 remy, lpatt(shortdash)) ///
			, scheme(s1mono) title("Cumulative Number of Dissolutions") subtitle("By Year and Type") ///
			xlabel(, labsize(small)) ylabel(0 20000 "20k" 40000 "40k" 60000 "60k" 80000 "80k" 100000 "100k", labsize(small)) ///
			ytitle("Number of dissolutions") xtitle("Year") ///
			legend(label(1 "Voluntary removal") label(2 "Wound up") label(3 "Other reason") rows(1) size(small)) ///
			note("Source: TSRC. Produced: $S_DATE.", size(vsmall))
		graph export $path6\ew_cunum_orgdiss_`fdate'.png, replace width(4096)
	restore

	
********************************************************************************


********************************************************************************	
	
	
/** 3. Statistical modelling **/
/*
	Estimate logit and multinomial regressions.
		
	Estimate linear probability models to check robustness of findings.
*/

** Independent variable macros **

// Filers

global indvars "ib6.period ib5.field incorp ib1.aob zinc_only income_vul_dum gap_year_dum"
/*
	Add income_vul_per_year as an alternative to income_vul_dum.
*/

** Logit **

// Filers and non-missing observations

logit deregistered $indvars if nomiss, vce(robust)
fitstat
listcoef, help

	** Interactions
	/*
		Largest effects * other inputs.
	*/
	
	logit deregistered $indvars income_vul_dum#ib5.field gap_year_dum#ib5.field if nomiss, vce(robust)

	// Diagnostics
	
	** Multicollinearity
	/*
		Not working: "factor-variable and time-series operators not allowed."
	*/
	
	collin period field incorp aob zinc_only income_vul_dum gap_year_dum if nomiss
	
	** Overall significance of categorical variables
	
	test 2.aob 3.aob // significant overall
	test 1.field 2.field 3.field 4.field // significant overall
	test 1.period 2.period 3.period 4.period 5.period // significant overall

	
	// Graph coefficients

	quietly logit, coeflegend noheader // recover variable names
	#delimit ;
	coefplot, baselevels drop(_cons 6.period 5.field 0.incorp 1.aob) xline(0)
			  ytitle("Independent Variables" " ") xtitle(" " "Log Odds")
			  title("Regression Model of Dissolution",
			  size(medium) justification(right)) ylab(, labsize(small) nogrid) xlab(, nogrid)
			  subtitle("Binary outcome", size(medsmall) justification(right))
				grid(none)
				msize(medium)
			   scheme(s1mono)
			   note("Adjusted R-Squared =.20" "* p < .05, ** p < .01, *** p < .001")
			   name(myplot, replace)
			   ;
	#delimit cr
	
	graph export $path6\ew_logit_results_`fdate'.png, replace width(4096)

	
** Mlogit **
/*
	See Breen et al. (2018) for guidance on interpreting the coefficients from these models.
*/
	
mlogit orgdiss $indvars if nomiss, base(0) vce(robust)
fitstat
listcoef	
	
	// Store results of -listcoef- in a matrix
	
	mat x = r(table) // store results in a matrix
	*mat li x
	/*
		See CITM syntax for how to store these results in a data set.
	*/
	
parmest, format(estimate min95 max95 %8.2f p) list(,) saving($path3\ew_mlogit_results.dta, replace) // store parameter estimates in a data set

	
	// Diagnostics
	
	** Interactions
	/*
		Being incorporated * other inputs.
	*/
	
	*mlogit orgdiss $indvars income_vul_dum#ib5.field gap_year_dum#ib5.field if nomiss, base(0) vce(robust)
	
	
	** Multicollinearity
	/*
		Not working: "factor-variable and time-series operators not allowed."
	*/
	
	collin period field incorp aob zinc_only income_vul_dum gap_year_dum if nomiss
	
	** Overall significance of categorical variables
	
	test 2.aob 3.aob // significant overall
	test 1.field 2.field 3.field 4.field // significant overall
	test 1.period 2.period 3.period 4.period 5.period // significant overall
	
	
	** Significance of differences between outcomes
	/*
		I think I can get the same tests from the -listcoef- command. [YES I CAN]
	*/
	
	
	** Predicted probabilities
	/*
		For largest effects in the model.
	*/
	
	predict p1 p2 p3 p4
	
	// Period 

	
	** Marginal effects
	/*
		Predicted probabilities and discrete change.
	*/
	/*
	margins period, atmeans predict(outcome(1))
		marginsplot, name(vr)
	margins period, atmeans predict(outcome(2))
		marginsplot, name(wu)
	margins period, atmeans predict(outcome(3))
		marginsplot, name(ot)
	graph combine vr wu ot, ycommon scheme(s1mono)	
	*/
	
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
		
	
	// Field of activity
	
	preserve
		keep if parm=="1.field" | parm=="2.field" | parm=="3.field" | parm=="4.field" // drop estimates for base categories (i.e. estimate==0) and other variables 
		tab var
		tab var, nolab
		recode var 1=1 5=2 8=3 10=4
		
		twoway (scatter estimate var if eq=="Voluntary_removal", msymbol(circle_hollow) msize(medlarge)) ///
			(scatter estimate var if eq=="Wound_up", msymbol(Th) msize(medlarge)) ///
			(scatter estimate var if eq=="Other_reason", msymbol(Dh) msize(medlarge)) ///
			, title("Regression Coefficients") subtitle("By Dissolution Type") ytitle("Log odds") xtitle("Independent variables") ///
			yline(0, lcolor(gs10)) ///
			xlab(0 " " 1 "Religion" 2 "Social Services" 3 "Development" 4 "Culture & Recreation" 5 " ", labsize(vsmall)) ///
			ylab(, labsize(vsmall)) ///
			legend(label(1 "Voluntary removal") label(2 "Wound up") label(3 "Other reason") rows(1) size(small)) ///
			scheme(s1mono)
		graph export $path6\ew_mlogit_orgdiss_indvars_1.png, replace width(4096)	
	restore	
	
	
	// Period
	
	preserve
		keep if parm=="1.period" | parm=="2.period" | parm=="3.period" | parm=="4.period" | parm=="5.period" // drop estimates for base categories (i.e. estimate==0) and other variables 
		tab var
		tab var, nolab
		recode var 2=1 6=2 9=3 11=4 12=5
		
		twoway (scatter estimate var if eq=="Voluntary_removal", msymbol(circle_hollow) msize(medlarge)) ///
			(scatter estimate var if eq=="Wound_up", msymbol(Th) msize(medlarge)) ///
			(scatter estimate var if eq=="Other_reason", msymbol(Dh) msize(medlarge)) ///
			, title("Regression Coefficients") subtitle("By Dissolution Type") ytitle("Log odds") xtitle("Independent variables") ///
			yline(0, lcolor(gs10)) ///
			xlab(1 "Pre 1918" 2 "1919-1945" 3 "1946-1965" 4 "1966-1978" 5 "1979-1992", labsize(vsmall)) ///
			ylab(, labsize(vsmall)) ///
			legend(label(1 "Voluntary removal") label(2 "Wound up") label(3 "Other reason") rows(1) size(small)) ///
			scheme(s1mono)
		graph export $path6\ew_mlogit_orgdiss_indvars_2.png, replace width(4096)	
	restore
	
	
	// Remaining variables
	
	preserve
		keep if parm=="incorp" | parm=="gap_year_dum" | parm=="income_vul_dum" | parm=="zinc_only"
		tab var
		tab var, nolab
		recode var 15=1 16=2 17=3 18=4
		
		twoway (scatter estimate var if eq=="Voluntary_removal", msymbol(circle_hollow) msize(medlarge)) ///
			(scatter estimate var if eq=="Wound_up", msymbol(Th) msize(medlarge)) ///
			(scatter estimate var if eq=="Other_reason", msymbol(Dh) msize(medlarge)) ///
			, title("Regression Coefficients") subtitle("By Dissolution Type") ytitle("Log odds") xtitle("Independent variables") ///
			yline(0, lcolor(gs10)) ///
			xlab(0 " " 1 "Inconsistent filer" 2 "Experienced loss of income" 3 "Incorporated" 4 "Zero-income filer" 5 " ", labsize(vsmall)) ///
			ylab(, labsize(vsmall)) ///
			legend(label(1 "Voluntary removal") label(2 "Wound up") label(3 "Other reason") rows(1) size(small)) ///
			scheme(s1mono)
		graph export $path6\ew_mlogit_orgdiss_indvars_3.png, replace width(4096)	
	restore	
