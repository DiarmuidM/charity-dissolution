// File: ma_nz_data_analysis_20190909.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 09/09/2019

******* New Zealand data analysis *******

/* 
	This DO file analyses NZ charity data:
		- time-series of deregistrations (by reason and overall)
		- cross-sectional and longitudinal predictive models
*/


/** 0. Define paths **/

global dfiles "C:\Users\t95171dm\Dropbox\" // location of data files
global rfiles "C:\Users\t95171dm\projects" // location of syntax and outputs
global diarmuid "C:\Users\t95171dm\projects\mission_accomp\syntax" // location of "project_paths.doi"

include "$diarmuid\project_paths.doi"


********************************************************************************


********************************************************************************	


/** 1. Import data **/

** Charity Register **

use $path3\nz_charreg_analysis_20190910.dta, clear
count
desc, f
notes

	
********************************************************************************


********************************************************************************	
	
	
/** 2. Descriptive analysis **/

** Create independent variables **
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

	// Organisation age
	
	tab orgage // deal with "-1" value for this variable
	gen orgage_dum = orgage // try a different functional form
	recode orgage_dum 0/9=1 10/12=0 *=.
	tab orgage_dum
	label variable orgage_dum "Recently registered"

	// Donative vs commercial

	tab mndon_maj

	// Funder

	gen funder = activity
	recode funder 2 3 7=1 *=0

	// Children and young people 

	gen cyp = beneficiary
	recode cyp 2=1 *=0

	// Education sector

	gen edsec = sector
	recode edsec 7=1 *=0 

	// Government funding

	tab1 sourcesoffunds, sort
	gen gov = 0 if sourcesoffunds!=""
	replace gov = 1 if regex(sourcesoffunds, "Government")
	tab gov

	// Area of operation

	tab areaop
	
	
	// Construct samples
	/*
		This should determine which variables are included in the models i.e. most variables come from
		the annual return.
	*/

	gen all = 1
	gen filers = (ar_merge==3)
	tab1 all filers


** Sample summary statistics **
/*
	Produce a paragraph and table summarising the characteristics of the sample across categories of our outcomes:
		- `deregistered'
		- `orgdiss'
	
	The independent variables to describe are:
		- orgtype orgage mninc_ln edsec cyp areaop don_maj gov mnemptotal mnvoltotal orgtt
		- conduct a separate analysis for `inc_diverse' as it severly restricts the sample
		
	Every descriptive analysis should be accompanied by the following condition: "if nomiss". This restricts the sample
	to the observations included in our statistical models.
		
	See example below.	
*/

mdesc orgtype orgage mninc_ln edsec cyp areaop don_maj gov mnemptotal mnvoltotal orgtt
mark nomiss if filers
tab nomiss
markout nomiss orgtype orgage mninc_ln edsec cyp areaop don_maj gov mnemptotal mnvoltotal orgtt
tab nomiss
label variable nomiss "Identifies observations with no missing values for "

	// Bivariate associations
	
	foreach var in orgtype orgage_dum edsec cyp areaop don_maj gov {
		tab `var' orgdiss if nomiss, col
	}
	
	foreach var in mninc_ln mnemptotal mnvoltotal orgtt {
		table orgdiss if nomiss, c(mean `var' sd `var' n `var')
	}


** Dependent variables **

tab1 deregistered orgdiss if all
tab1 deregistered orgdiss if nomiss

tab deregistered orgtype if all, col all
tab deregistered orgtype if nomiss, col all

tab orgdiss orgtype if all, col all
tab orgdiss orgtype if nomiss, col all
/*
	Something going on with organisation type - it highly predictive.
*/

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
			xlabel(2008(2)2020, labsize(small)) ylabel(0(1000)4000, labsize(small)) ///
			ytitle("Number of dissolutions") xtitle("Year") ///
			legend(label(1 "Failure to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
			note("Source: Charities Services. Produced: $S_DATE.", size(vsmall))
		graph export $path6\nz_cunum_orgdiss_`fdate'.png, replace width(4096)
	restore
	/*
		Why haven't we observed any voluntary removals for 2019?
	*/

	
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

** Independent variable macros **

// Filers

global popeco_fil "mninc_ln orgage_dum ib0.orgtype edsec cyp"
global resdep_fil "mndon_maj gov" // add in `mnempcomp_share funexp_share mninc_diverse' at a later stage
global contro_fil "mnemptotal mnvoltotal orgtt ib1.areaop"


** Logit **

// Filers and non-missing observations

logit deregistered $popeco_fil $resdep_fil $contro_fil if nomiss, vce(robust)
fitstat
listcoef, help

	// Diagnostics
	
	** Multicollinearity
	/*
		Not working: "factor-variable and time-series operators not allowed."
	*/
	*collin mninc_ln orgage orgtype edsec cyp areaop $resdep_fil $contro_fil if nomiss
	
	** Overall significance of categorical variables
	
	test 2.areaop 3.areaop // insignificant overall
	test 1.orgtype 2.orgtype // significant overall

	// Graph coefficients

	quietly logit, coeflegend noheader // recover variable names
	#delimit ;
	coefplot, baselevels drop(_cons 0.orgtype 1.areaop) xline(0)
			  ytitle("Independent Variables" " ") xtitle(" " "Log Odds")
			  title("Regression Model of Dissolution",
			  size(medium) justification(right)) ylab(, labsize(small) nogrid) xlab(, nogrid)
			  subtitle("Binary outcome", size(medsmall) justification(right))
			  coeflabels(mninc_ln = "Size" orgage = "Age" 1.orgtype = "Society or institution" 2.orgtype = "Trustees of a trust" 
				edsec = "Education" cyp = "Children & Young People" 2.areaop = "National" 3.areaop = "International" mndon_maj = "Donations"
				gov = "Government" mnemptotal = "Employees" mnvoltotal = "Volunteers" orgtt = "Trustees")
				headings(mninc_ln = "{bf:Population Ecology}" mndon_maj = "{bf:Resource Dependence}" mnemptotal = "{bf:Controls}")
				grid(none)
				msize(medium)
			   scheme(s1mono)
			   note("Adjusted R-Squared =.56" "* p < .05, ** p < .01, *** p < .001")
			   name(myplot, replace)
			   ;
	#delimit cr
	graph export $path6\nz_logit_coefplot_`fdate'.png, replace width(4096)

	
** Mlogit **
/*
	See Breen et al. (2018) for guidance on interpreting the coefficients from these models.
*/
	
mlogit orgdiss $popeco_fil $resdep_fil $contro_fil if nomiss, base(0) vce(robust)
fitstat
listcoef	
	
	// Store results of -listcoef- in a matrix
	
	mat x = r(table) // store results in a matrix
	*mat li x
	/*
		See CITM syntax for how to store these results in a data set.
	*/
	
parmest, format(estimate min95 max95 %8.2f p) list(,) saving($path3\nz_mlogit_results.dta, replace) // store parameter estimates in a data set

	
	// Diagnostics
	
	** Interactions
	/*
		Orgtype * other inputs.
	*/
	
	mlogit orgdiss $popeco_fil $resdep_fil $contro_fil i.orgtype#c.mninc_ln i.orgtype#i.mndon_maj i.orgtype#i.gov i.orgtype#i.orgage_dum ///
		i.orgtype#i.edsec i.orgtype#i.cyp if nomiss, base(0) vce(robust)
	
	
	** Multicollinearity
	/*
		Not working: "factor-variable and time-series operators not allowed."
	*/
	
	*collin mninc_ln orgage orgtype edsec cyp areaop $resdep_fil $contro_fil if nomiss

	
	** Overall significance of categorical variables
	
	test 2.areaop 3.areaop // significant overall
	test 1.orgtype 2.orgtype // significant overall
	
	
	** Significance of differences between outcomes
	
	test [Failed_to_file]mninc_ln = [Voluntary_removal]mninc_ln = [Wound_up]mninc_ln // not statistically significantly different
	test [Failed_to_file]1.orgtype = [Voluntary_removal]1.orgtype = [Wound_up]1.orgtype
	test [Failed_to_file]2.orgtype = [Voluntary_removal]2.orgtype = [Wound_up]2.orgtype
	test [Failed_to_file]2.areaop = [Voluntary_removal]2.areaop = [Wound_up]2.areaop
	test [Failed_to_file]3.areaop = [Voluntary_removal]3.areaop = [Wound_up]3.areaop
	test [Failed_to_file]orgage = [Voluntary_removal]orgage = [Wound_up]orgage
	test [Failed_to_file]edsec = [Voluntary_removal]edsec = [Wound_up]edsec
	test [Failed_to_file]cyp = [Voluntary_removal]cyp = [Wound_up]cyp
	test [Failed_to_file]mndon_maj = [Voluntary_removal]mndon_maj = [Wound_up]mndon_maj
	*test [Failed_to_file]inc_diverse = [Voluntary_removal]inc_diverse = [Wound_up]inc_diverse
	test [Failed_to_file]gov = [Voluntary_removal]gov = [Wound_up]gov
	test [Failed_to_file]mnemptotal = [Voluntary_removal]mnemptotal = [Wound_up]mnemptotal
	test [Failed_to_file]mnvoltotal = [Voluntary_removal]mnvoltotal = [Wound_up]mnvoltotal
	test [Failed_to_file]orgtt = [Voluntary_removal]orgtt = [Wound_up]orgtt
	/*
		I think I can get the same tests from the -listcoef- command. [YES I CAN]
	*/
	
	
	** Predicted probabilities
	/*
		For largest effects in the model.
	*/
	
	predict p1 p2 p3 p4
	
	// Size 
	/*
		Do this for the original scale.
	*/
	
	twoway (qfit p2 mninc_ln , lpatt(solid)) (qfit p3 mninc_ln , lpatt(longdash)) (qfit p4 mninc_ln , lpatt(shortdash))  ///
		, title("Predicted Probability of Dissolution") subtitle("By Dissolution Type") ///
		ytitle("Predicted probability") xtitle("Organisation size (natural log)") ///
		ylabel(, labsize(small)) xlabel(, labsize(small)) ///
		legend(label(1 "Failed to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
		scheme(s1mono) ///
		note("Source: Charities Services. Produced: $S_DATE." ///
			"Graph displays quadratic line of best fit between predicted dissolution rate and organisation size.", span size(vsmall))
	graph export $path6\nz_mlogit_pprob_size_`fdate'.png, replace width(4096)
	
	
	// Government is main funder
	/*
		TASK: graph predicted probabilities by this dummy variable (```gov```).
	*/
	
	preserve
		
		collapse p2 p3 p4, by(gov)
		desc, f
		
		twoway (scatter p2 gov) (lfit p2 gov , lpatt(solid)) (scatter p3 gov) (lfit p3 gov , lpatt(longdash)) ///
			(scatter p4 gov) (lfit p4 gov , lpatt(shortdash))  ///
			, title("Predicted Probability of Dissolution") subtitle("By Dissolution Type") ///
			ytitle("Predicted probability") xtitle("Government in main funder") ///
			ylabel(, labsize(small)) xlabel(0 1, labsize(small)) ///
			legend(label(1 "Failed to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
			scheme(s1mono) ///
			note("Source: Charities Services. Produced: $S_DATE." ///
				"Graph displays quadratic line of best fit between predicted dissolution rate and organisation age.", span size(vsmall))
		graph export $path6\nz_mlogit_pprob_gov_`fdate'.png, replace width(4096)
	
	restore
	
	// Organisation type
	/*
		TASK: graph predicted probabilities by this dummy variable (```orgtype```).
	*/
	
	
	// Age
	/*
		This is really a categorical variable, need to graph another way (e.g. mean probability per year a la Cleveland graph).
	*/
	
	twoway (qfit p2 orgage , lpatt(solid)) (qfit p3 orgage , lpatt(longdash)) (qfit p4 orgage , lpatt(shortdash))  ///
		, title("Predicted Probability of Dissolution") subtitle("By Dissolution Type") ///
		ytitle("Predicted probability") xtitle("Organisation age") ///
		ylabel(, labsize(small)) xlabel(, labsize(small)) ///
		legend(label(1 "Failed to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
		scheme(s1mono) ///
		note("Source: Charities Services. Produced: $S_DATE." ///
			"Graph displays quadratic line of best fit between predicted dissolution rate and organisation age.", span size(vsmall))
	graph export $path6\nz_mlogit_pprob_age_`fdate'.png, replace width(4096)
	/*
		Why negative probabilities? There are none generated by -predict', must be to do with the graph.
	*/

		twoway (lfit p2 orgage , lpatt(solid)) (lfit p3 orgage , lpatt(longdash)) (lfit p4 orgage , lpatt(shortdash))  ///
			, title("Predicted Probability of Dissolution") subtitle("By Dissolution Type") ///
			ytitle("Predicted probability") xtitle("Organisation age") ///
			ylabel(, labsize(small)) xlabel(, labsize(small)) ///
			legend(label(1 "Failed to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
			scheme(s1mono) ///
			note("Source: Charities Services. Produced: $S_DATE." ///
				"Graph displays quadratic line of best fit between predicted dissolution rate and organisation age.", span size(vsmall))
	
		twoway (scatter p2 orgage) (scatter p3 orgage) (scatter p4 orgage)  ///
			, title("Predicted Probability of Dissolution") subtitle("By Dissolution Type") ///
			ytitle("Predicted probability") xtitle("Organisation age") ///
			ylabel(, labsize(small)) xlabel(, labsize(small)) ///
			legend(label(1 "Failed to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
			scheme(s1mono) ///
			note("Source: Charities Services. Produced: $S_DATE." ///
				"Graph displays quadratic line of best fit between predicted dissolution rate and organisation age.", span size(vsmall))


	
	** Marginal effects
	/*
		Predicted probabilities and discrete change.
	*/

	margins orgtype, atmeans predict(outcome(1))
		marginsplot, name(ftf)
	margins orgtype, atmeans predict(outcome(2))
		marginsplot, name(vr)
	margins orgtype, atmeans predict(outcome(3))
		marginsplot, name(wu)
	graph combine ftf vr wu, ycommon scheme(s1mono)	
	/*
		Makes no sense to hold area of operation at mean values, unless transform into dummy variables.
	*/

	margins, dydx(orgtype) atmeans predict(outcome(1))
	margins, dydx(orgtype) atmeans predict(outcome(2))
	margins, dydx(orgtype) atmeans predict(outcome(3))
	
	margins, dydx(orgtt) at(orgtt=(1(1)20)) atmeans predict(outcome(1))
	margins, dydx(orgtt) atmeans predict(outcome(1))

	margins, dydx(orgtt) atmeans predict(outcome(2))
	margins, dydx(orgtt) atmeans predict(outcome(3))

	margins, dydx(mninc_ln) atmeans predict(outcome(1))
	margins, dydx(mninc_ln) atmeans predict(outcome(2))
	margins, dydx(mninc_ln) atmeans predict(outcome(3))

	// Graph coefficients
	/*
		Produce a graph for each set of variables. [DONE]
		Add confidence intervals (spike graph?).
		Common yaxes.
		Add info on significance tests for differences between outcomes.
		
	*/
	use $path3\nz_mlogit_results.dta, clear
	
	drop if eq=="Registered"
	drop if parm=="_cons"
	encode parm, gen(var)
	tab var
		
		** Orgtype variables
		
		preserve
			keep if var==2 | var==5 
			tab var
			tab var, nolab
			recode var 2=3
			l parm estimate var eq
			count
			
			twoway (scatter estimate var if eq=="Failed_to_file", msymbol(circle_hollow) msize(medlarge)) ///
				(scatter estimate var if eq=="Voluntary_removal", msymbol(Th) msize(medlarge)) ///
				(scatter estimate var if eq=="Wound_up", msymbol(Dh) msize(medlarge)) ///
				, title("Regression Coefficients") subtitle("By Dissolution Type") ytitle("Organisation Type") xtitle("Log odds") ///
				xline(0, lcolor(gs10)) ///
				ysc(r(1 6)) ///
				ylab(2 "Society" 5 "Trust" , labsize(small)) xlabel(, labsize(small)) ///
				legend(label(1 "Failure to file") label(2 "Voluntary removal") label(3 "Wound up") rows(1) size(small)) ///
				scheme(s1mono)
			graph export $path6\nz_mlogit_orgdiss_orgtype.png, replace width(4096)	
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
			graph export $path6\nz_mlogit_orgdiss_othvars.png, replace width(4096)	
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
			graph export $path7\nz_mlogit_orgdiss_contro.png, replace width(4096)	
		restore
