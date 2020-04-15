// File: ma_aus_data_analysis_20190923.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 23/09/2019

******* Australia data analysis *******

/* 
	This DO file analyses Aus charity data:
		- time-series of deregistrations (by reason and overall)
		- cross-sectional and longitudinal predictive models
*/


/** 0. Define paths **/

global dfiles "C:\Users\t95171dm\Dropbox\" // location of data files
global rfiles "C:\Users\t95171dm\projects" // location of syntax and outputs
global diarmuid "C:\Users\t95171dm\projects\mission_accomp\syntax" // location of "project_paths.doi"

include "$diarmuid\project_paths.doi"


/** 1. Import data **/

** Charity Register **

use $path3\aus\aus_charreg_analysis_20190910.dta, clear
count
desc, f
notes


/** 2. Descriptive analysis **/

** Construct samples **
/*
	This should determine which variables are included in the models i.e. most variables come from
	the annual return.
*/

gen all = 1
gen filers = (ar_merge==3)
tab1 all filers

** Dependent variable **

tab orgdiss
tab orgdiss if filers
/*
	Very few examples of voluntary removal that are not winding ups; serious implications for statistical modelling.
	
	We lose a lot of the failure to file observations, which makes sense given you need to file to appear in the 
	annual returns data.
*/

	// Rate of dissolution over time
	
	tab statusy
	
	preserve
		gen freq=1
		keep if orgdiss > 0 & statusy > 2008
		collapse (count)freq , by(statusy orgdiss)
		
		forvalues i = 1/4 {
			gen cunum`i' = sum(freq) if orgdiss==`i'
		}
		
		twoway (line cunum1 statusy, lpatt(solid)) (line cunum2 statusy, lpatt(longdash)) (line cunum3 statusy, lpatt(shortdash)) ///
			(line cunum4 statusy, lpatt(shortdash)) ///
			, scheme(s1color) title("Cumulative Number of Dissolutions") subtitle("By year removed") ///
			xlabel(2012(1)2019, labsize(small)) ylabel(, labsize(small)) ///
			ytitle("Number of dissolutions") xtitle("Year") ///
			legend(label(1 "Failure to file") label(2 "Voluntary removal") label(3 "Wound up") label(4 "Failure to file (other)") rows(2) size(small)) ///
			note("Source: ACNC. Produced: $S_DATE.", size(vsmall))
		graph export $path6\aus_cunum_orgdiss_`fdate'.png, replace width(4096)
	restore

	
/** 3. Statistical modelling **/
/*
	Estimate logit and multinomial regressions. For each type, estimate on two samples:
		- whole sample
		- only charities that filed an annual return
			
	Estimate linear probability models to check robustness of findings.
*/




** Examine dependent variables **

tab1 deregistered orgdiss if all
tab1 deregistered orgdiss if filers

tab deregistered rtype, col all
tab orgdiss rtype, col all
tab deregistered brc, col all // brc is only found in the annual returns data, hence don't use it as a predictor in the first model


** Create independent variables **
/*
	Theoretical model being tested (see written notes on this):
	
		- Population ecology:
			* Size
			* Age
			* Sector
			* Purposes/beneficiaries
			* Density (by sector or area)
		- New institutionalism (not sure I have measures of these):
			* Legitmacy (could be government funding; links with other charities - through trustees)
			* Conformance to codes/rule etc
		- Resource dependence (see Lu et al. 2019 for operationalisations):
			* Donative vs commercial
			* Main source of funds (e.g. public funding)
			* Revenue diversification
		- Controls:
			* Year (active, not registered as this is captured in age)
			* Board size
*/


// Area of operation

tab1 areaop_*
/*
	How can a charity have a total of zero areas?
*/


** Independent variable macros **

// All charities

global popeco_all "overop areaop_total cp_total bg_total"
global contro_all "orgct pbi hpc"
*global newins "" // no variables for this yet; possibly argue that public funding is a source of legitimacy


// Filers

global popeco_fil "orgage mninc_ln overop areaop_total cp_total bg_total"
global resdep_fil "gov" // add in `don_maj' and `inc_diverse' at a later stage
global contro_fil "orgct pbi hpc"
*global newins "" // no variables for this yet; possibly argue that public funding is a source of legitimacy


** Bivariate associations **


** Missing data **

mdesc $popeco_fil $resdep_fil $contro_fil if filers
/*
	Income diversification and majority donations (and vols) greatly reduce the sample size - dig into why.
*/


** Logit **

// Filers

logit deregistered $popeco_fil $resdep_fil $contro_fil if filers
fitstat
listcoef
/*
	Not much explanatory power.
*/

	// Diagnostics
	
	** Overall significance of categorical variables


	// Graph coefficients

	#delimit ;
	coefplot, baselevels drop(_cons) xline(0)
			  ytitle("Independent Variables" " ") xtitle(" " "Regression Coefficient")
			  title("Regression Model of Dissolution",
			   size(medium) justification(right) ) ylab(, nogrid) xlab(, nogrid)
			   subtitle("Binary outcome", size(medsmall) justification(right))
			   scheme(s1mono)
			   note("Adjusted R-Squared =.nn")
			   name(myplot, replace)
			   ;
	#delimit cr	

// All charities

logit deregistered $popeco_all $contro_all
fitstat
listcoef

	// Diagnostics
	
	** Overall significance of categorical variables


	// Graph coefficients

	#delimit ;
	coefplot, baselevels drop(_cons) xline(0)
			  ytitle("Independent Variables" " ") xtitle(" " "Regression Coefficient")
			  title("Regression Model of Dissolution",
			   size(medium) justification(right) ) ylab(, nogrid) xlab(, nogrid)
			   subtitle("Binary outcome", size(medsmall) justification(right))
			   scheme(s1mono)
			   note("Adjusted R-Squared =.nn")
			   name(myplot, replace)
			   ;
	#delimit cr	

	
** Mlogit **
/*
	See Breen et al. (2018) for guidance on interpreting the coefficients from these models.
*/

// Filers	
	
mlogit orgdiss $popeco_fil $resdep_fil $contro_fil if filers, base(0)
fitstat
listcoef
/*
	Not much explanatory power.
*/
	
	// Store results of -listcoef- in a matrix
	
	mat x = r(table) // store results in a matrix
	*mat li x
	/*
		See CITM syntax for how to store these results in a data set.
	*/
	
parmest, format(estimate min95 max95 %8.2f p) list(,) saving($path3\aus_mlogit_filers_results.dta, replace) // store parameter estimates in a data set

	
	// Diagnostics
	
	** Overall significance of categorical variables
	
	
	** Significance of differences between outcomes
	
	test [Failed_to_file]orgct = [Voluntary_removal]orgct = [Wound_up]orgct // statistically significantly different
	/*
		I think I can get the same tests from the -listcoef- command. [YES I CAN]
	*/
	
	
	** Predicted probabilities
	
	capture predict p1 p2 p3 p4 p5
	
	
	
	** Marginal effects
	/*
		Predicted probabilities and discrete change.
	*/

	margins , atmeans predict(outcome(1))
		marginsplot, name(ftf)
	margins , atmeans predict(outcome(2))
		marginsplot, name(vr)
	margins , atmeans predict(outcome(3))
		marginsplot, name(wu)
	graph combine ftf vr wu, ycommon scheme(s1mono)	
	/*
		
	*/

	** Board size
	
	margins, dydx(orgct) at(orgct=(1(1)20)) atmeans predict(outcome(1))
	margins, dydx(orgct) atmeans predict(outcome(1))
	/*
		The first set of results indicates declining return on survival probability as board size increases (especially after 10).
		
		The second set of results represents the average marginal effect (i.e. a randomly selected charity could expect a decrease of
		.02 in the probability of failing to file for a one-unit increase in its board size).
	*/
	margins, dydx(orgct) atmeans predict(outcome(2))
	margins, dydx(orgct) at(orgct=(1(1)20)) atmeans predict(outcome(2))
	
	margins, dydx(orgct) atmeans predict(outcome(3))
	margins, dydx(orgct) at(orgct=(1(1)20)) atmeans predict(outcome(3))
	
	** Charitable purposes

	margins, dydx(cp_total) atmeans predict(outcome(1))
	margins, dydx(cp_total) at(cp_total=(1(1)12)) atmeans predict(outcome(1))
	
	margins, dydx(cp_total) atmeans predict(outcome(2))
	margins, dydx(cp_total) at(cp_total=(1(1)12)) atmeans predict(outcome(2))

	margins, dydx(cp_total) atmeans predict(outcome(3))
	margins, dydx(cp_total) at(cp_total=(1(1)12)) atmeans predict(outcome(3))
	/*
		The first set of results represents the average marginal effect (i.e. a randomly selected charity could expect a decrease of
		.03 in the probability of winding up for a one-unit increase in number of charitable purposes).
		
		The second set of results indicates declining return on survival probability as charitable purposes increases (especially after 3).
	*/



	// Graph coefficients
	/*
		Produce a graph for each set of variables. [DONE]
		Add confidence intervals.
		Common yaxes.
		Add info on significance tests for differences between outcomes.
		
	*/
	use $path3\aus_mlogit_filers_results.dta, clear
	
	drop if eq=="Registered"
	drop if parm=="_cons"
	encode parm, gen(var)
	tab var
		
		** All variables
		
		preserve
			
			twoway (scatter estimate var if eq=="Failed_to_file", msymbol(circle_hollow) msize(medlarge)) ///
				(scatter estimate var if eq=="Voluntary_removal", msymbol(Th) msize(medlarge)) ///
				(scatter estimate var if eq=="Wound_up", msymbol(Dh) msize(medlarge)) ///
				, title("Probability of Dissolution") subtitle("All indvars") ytitle("Log odds") xtitle(" ") ///
				yline(0, lcolor(gs10)) ///
				xlab(1 "AOO" 2 "BG" 3 "CP" 4 "Board Size" 5 "Overseas" , labsize(vsmall)) ylabel(, labsize(small)) ///
				legend(label(1 "Failure to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
				scheme(s1color)
			graph export $path7\aus_mlogit_orgdiss_allvars.png, replace width(4096)	
		restore
		