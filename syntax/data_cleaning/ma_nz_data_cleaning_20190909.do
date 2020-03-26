// File: ma_nz_data_cleaning_20190909.do
// Creator: Diarmuid McDonnell, Alasdair Rutherford
// Created: 09/09/2019

******* New Zealand data cleaning *******

/* This DO file marshals the raw charity charity to produce a data set suitable for analysis:
	- imports raw data in csv format
	- cleans these datasets
	- links these datasets
	- saves these datasets in Stata and CSV formats
	
	To Do:
	- Link area level data for NZ
	- Create remaining financial measures (e.g. debt level, investment income)
	
*/


/** 0. Define paths **/

global dfiles "C:\Users\mcdonndz-local\Dropbox" // location of data files
global rfiles "C:\Users\mcdonndz-local\Desktop" // location of syntax and outputs
global diarmuid "C:\Users\mcdonndz-local\Desktop\github\mission_accomp\syntax" // location of "project_paths.doi"

include "$diarmuid\project_paths.doi"


/** 1. Import data **/

** Trustees **
/*
	Think about using the linked data sets also.
*/

import delimited $path2\nz\Officers\nz_Officers_y0_m0_p0_integrity.csv, clear varn(1)
desc, f
count

	// Valid values of variables
	
	distinct contactid organisationid officerid
	/*
		It appears that every charity appears in the data; now, does the list of trustees only apply to
		the most recent annual return or is it a census? I think it's the latter.
	*/

	sort organisationid contactid
	l in 1/10
	
	
	codebook organisationid
	destring organisationid, replace
	rename organisationid orgid
	label variable orgid "Unique id of charity - internal regulatory reference"
	
		duplicates report orgid // most duplicates should be valid i.e. multiple trustees per charity
		drop if orgid==. // drop observations with no organisation id
		
	
	codebook contactid
	destring contactid, replace
	rename contactid tid
	label variable tid "Unique id of trustee - internal regulatory reference"
	/*
		Is this true? It would suggest that no charity shares a trustee with another organisation; perhaps it's the
		unique id of a trusteeship?
	*/
	
	
	codebook positionappointmentdate lastdateasanofficer
	gen appdate = date(positionappointmentdate, "DMY")
	gen resdate = date(lastdateasanofficer, "DMY")
	format appdate resdate %td
	drop positionappointmentdate lastdateasanofficer
	label variable appdate "Date trustee was appointed"
	label variable resdate "Date trustee resigned/was removed"

		foreach var in app res {
			gen `var'y = year(`var'date)
			tab `var'y
		}
		label variable appy "Year trustee was appointed"
		label variable resy "Year trustee resigned/was removed"

	
	codebook officerstatus
	tab officerstatus, sort miss
	tab officerstatus if ~missing(resdate)
	encode officerstatus, gen(tstatus)
	recode tstatus 1 6=1 2=2 3=3 4=4 5=5
	
		gen ct = tstatus
		recode ct 1/4=0 5=1  
		tab ct tstatus
	
	
	codebook positioninorganisation
	rename positioninorganisation trole
	label variable trole "Role of trustee in organisation e.g. President"
	/*
		Too many unique values - spit out into OpenRefine and do some normalising.
	*/
	

sort orgid
sav $path1\nz_trustees_20190909.dta, replace


** Beneficiaries **

import delimited $path2\nz\Beneficiaries\nz_Beneficiaries_y0_m0_p0_integrity.csv, clear varn(1)
desc, f
count

	// Keep relevant variables

	drop v*
	
	bro
	rename beneficiaryid benid
	count if missing(real(benid))
	replace benid = "" if missing(real(benid))
	destring benid, replace
	
	duplicates report benid
	duplicates drop benid, force
	label variable benid "Unique id of beneficiary"
	
	rename name bendesc
	label variable bendesc "Description of beneficiary"

sort benid
sav $path3\nz_beneficiaries_20190909.dta, replace


** Sector **

import delimited $path2\nz\Sectors\nz_Sectors_y0_m0_p0_integrity.csv, clear varn(1)
desc, f
count

	// Keep relevant variables

	drop v*
	
	rename sectorid secid
	count if missing(real(secid))
	replace secid = "" if missing(real(secid))
	destring secid, replace
	
	duplicates report secid
	duplicates drop secid, force
	label variable secid "Unique id of sector"
	
	rename name secdesc
	label variable secdesc "Description of sector"
	/*
		There is pleny of potential for text mining/extraction.
	*/
	

sort secid
sav $path3\nz_sectors_20190909.dta, replace


** Activties **

import delimited $path2\nz\Activities\nz_Activities_y0_m0_p0_integrity.csv, clear varn(1)
desc, f
count

	// Keep relevant variables

	drop v*
	
	rename activityid actid
	count if missing(real(actid))
	replace actid = "" if missing(real(actid))
	destring actid, replace
	
	duplicates report actid
	duplicates drop actid, force
	label variable actid "Unique id of activity"
	
	rename name actdesc
	label variable actdesc "Description of activity"

sort actid
sav $path3\nz_activities_20190909.dta, replace
		

** Source of Funds **

import delimited $path2\nz\SourceOfFunds\nz_SourceOfFunds_y0_m0_p0_integrity.csv, clear varn(1)
desc, f
count

	// Keep relevant variables

	capture drop v*
	
	rename sourceoffundsid srcid
	count if missing(real(srcid))
	replace srcid = "" if missing(real(srcid))
	destring srcid, replace
	
	duplicates report srcid
	duplicates drop srcid, force
	label variable srcid "Unique id of source"
	
	rename name srcdesc
	label variable srcdesc "Description of source"

sort srcid
sav $path3\nz_sources_20190909.dta, replace
		

** Area of Operation **

import delimited $path2\nz\AreaOfOperations\nz_AreaOfOperations_y0_m0_p0_integrity.csv, clear varn(1)
desc, f
count

	// Keep relevant variables

	capture drop v*
	
	rename areaofoperationid aooid
	capture count if missing(real(aooid))
	capture replace aooid = "" if missing(real(aooid))
	destring aooid, replace
	
	duplicates report aooid
	duplicates drop aooid, force
	label variable aooid "Unique id of source"
	
	rename name aoodesc
	label variable aoodesc "Description of source"

sort aooid
sav $path3\nz_aoo_20190909.dta, replace
		
		
** Charity Register **

import delimited $path2\nz\Organisations\nz_orgs_deregreasons_integrity.csv, clear
desc, f
count

	// Check for duplicates
	
	duplicates report *
	duplicates drop *, force
	
		duplicates report charityregistrationnumber
		duplicates list charityregistrationnumber // look to be caused by data parsing issues; drop
		duplicates drop charityregistrationnumber, force
		
		duplicates report organisationid
		duplicates list organisationid // valid duplication
		/*
			Need to deal with these, precludes using this variable as a unique id for merging, xtset etc.
		*/
		
	
	// Keep relevant variables
	
	keep organisationid accountid name charityregistrationnumber dateregistered deregistrationdate deregistrationreasons establishedbyparliamentact ///
		excemptioncomment isincorporated organisational_type registrationstatus society_institution trustees_trust exemptions ///
		grouptype groupid postaladdress_city postaladdress_country postaladdress_postcode mainactivityid mainbeneficiaryid mainsectorid dereg_act dereg_reason

	
	// Keep relevant cases
	
	drop if organisationid==""
	drop if name == ""
	drop if charityregistrationnumber==""
	drop if dateregistered==""

	
	// Check variable values
	
	codebook organisationid
	destring organisationid, replace
	rename organisationid orgid
	label variable orgid "Unique id of charity - internal regulatory reference"
	
	
	codebook accountid
	rename accountid accid
	label variable accid "Unique id of most recent annual return"
	
	
	codebook name
	l name in 1/50
	label variable name "Name of charity"
	
	
	codebook charityregistrationnumber
	rename charityregistrationnumber ccnum
	label variable ccnum "Unique id of charity - registration number"
	
	
	codebook postaladdress_postcode
	l postaladdress_postcode in 1/100, clean noobs // varying lengths, they should be four digits
	rename postaladdress_postcode postcode
	gen postcode_len = strlen(postcode)
	tab postcode_len // 7 percent are three digits; just work with the four digit codes for now
	gen postcode_area_id = substr(postcode, 1, 2) // first two digits identify the area
	l postcode postcode_area_id in 1/100
	count if missing(real(postcode))
	replace postcode = "" if missing(real(postcode))
	destring postcode, replace
	replace postcode = . if postcode_len!=4
	gen region = postcode_area_id
	replace region = "" if missing(real(region))
	destring region, replace
	tab region
	recode region 1/5=1 6/26=2 30/31=3 32/39=4 40/42=5 43/49=6 50/53 55 57/58 60/64 69=7 70/72=8 73/82 84/86 88/89=9 90 92/98=10 *=.
	label define region_lab 1 "Northland" 2 "Auckland" 3 "Bay of Plenty" 4 "Waikato" 5 "Gisborne-Hawkes Bay" 6 "Taranaki–Manawatu–Whanganui" ///
		7 "Wellington–Wairarapa" 8 "Nelson–Malborough–Tasman" 9 "Canterbury–West Coast" 10 "Otago-Southland"
	label values region region_lab
	tab region
	
	
	
	codebook dereg_reason
	encode dereg_reason, gen(orgdiss)
	recode orgdiss 2 4 6=. 1=1 3=0 5=2 7=3 // set smallest categories to missing
	label drop orgdiss
	label define orgdiss_lab 0 "Registered" 1 "Failed to file" 2 "Voluntary removal" 3 "Wound up"
	label values orgdiss orgdiss_lab
	label variable orgdiss "Dissolution status of charity"
	
	codebook dateregistered
	gen regd = date(dateregistered, "DMY")
	format regd %td
	drop dateregistered
	label variable regd "Date charity was registered with Regulator"

		gen regy = year(regd)
		tab regy
		label variable regy "Year charity was registered with Regulator"
		/*
			Not sure how useful this variable is due to the default registration date (2008).
			
			Create alternative measures.
		*/

		gen regy_dum = regy
		recode regy_dum min/2008=0 2009/max=1
		tab regy_dum regy
		
		
	codebook mainactivityid
	rename mainactivityid actid
	count if missing(real(actid))
	replace actid = "" if missing(real(actid))
	destring actid, replace
	
	
	codebook mainbeneficiaryid
	rename mainbeneficiaryid benid
	count if missing(real(benid))
	replace benid = "" if missing(real(benid))
	destring benid, replace
	
	
	codebook mainsectorid
	rename mainsectorid secid
	
	
	codebook registrationstatus
	tab registrationstatus
	label variable registrationstatus "Current registration status of charity"
	encode registrationstatus, gen(deregistered)
	recode deregistered 1=1 2=0
	label define dreg_lab 0 "Registered" 1 "Deregistered"
	label values deregistered dreg_lab
	tab registrationstatus deregistered
	
	
	tab isincorporated
	gen company = 0
	replace company = 1 if isincorporated == "true"
	drop isincorporated
	
	
	tab organisational_type
	gen orgtype = 0
	replace orgtype = 1 if organisational_type == "Society or institution"
	replace orgtype = 2 if organisational_type == "Trustees of a trust"
	drop organisational_type
	/*
		Revist this coding: there is already a value of zero for organisational_type in the raw data.
	*/
	
	
	// Save version for merging with trustee data
	
	preserve
		sort orgid
		keep orgid accid dereg_reason orgdiss
		sav $path1\nz_charreg_merge_20190909.dta, replace
	restore

sort ccnum 
sav $path1\nz_charreg_20190909_v1.dta, replace


** Annual Returns **

forvalues yr = 2007(1)2019 {

	di "Year: `yr'"

	import delimited "$path2\nz\GrpOrgAllReturns\GrpOrgAllReturns_yr`yr'_integrity_geog.csv", clear
	
	// Get rid of rows where the data has been corrupted
	tab endofyeardayofmonth, missing
	capture replace endofyeardayofmonth = "0" if endofyeardayofmonth==.
	destring endofyeardayofmonth, replace force
	drop if endofyeardayofmonth==.
	replace endofyeardayofmonth = . if endofyeardayofmonth==0

	// Make sure that all the rest of the financial variables are bytes
	quietly destring 	endofyeard~h  allotherin~e  costofserv~n  interestpaid  otherinves~e  totalliabi~y totalliabilities gainonprop~n  debtorsand~s  accumulate~a  materialex~1 ///
				percentage~s  allothersh~s  costoftrad~s  inventory     restricted~s  allothergr~p  othercompr~e  moneyheldo~s  accumulate~s   ///
				annualretu~d  avgallpaid~k  depreciation  investments   salariesan~s  servicetra~e  totalcompr~e  moneyowedt~i  reserves      materialex~2 ///
				allcurren~ts  avgallvolu~k  donationsk~a  land          status        maraefunds    comprehens~o  othercurre~s  minorityin~t   ///
				allcurren~es  avgnovolun~k  endowmentf~s  membership~s  totalassets   maoritrust~d  receiptsfr~s  propertypl~t  otherresou~s  materialex~3 ///
				allnoncur~ts  bequests      generalacc~s  netsurplus~r  totalequity   otherreven~t  receiptsof~s  intangible~s  moneypayab~y   ///	 
				allnoncur~es  buildings     govtgrants~s  newzealand~s  totalexpen~e  otherreven~s  purchaseof~s  investment~y  othercommi~s  materialex~4 ///
				allotherex~e  cashandban~s  grantspa~enz  numberoffu~s  totalgross~e  fundraisin~s  repayments~s  totalasse~es  guarantees	///
				allotherfi~s  computersa~t  grantspa~nnz  numberofpa~s  totalliabi~s  grantsordo~d  receivable~i  capitalcon~s  mater~1label, replace

	keep 		id entitytype name charityregistrationnumber companiesofficenumber dateregistered deregistrationdate deregistrationreasons  endofyeardayofmonth financialpositiondate ///
				isincorporated maori_trust_brd marae_reservation organisational_type percentage_spent_overseas registrationstatus annualreturnduedate annualreturnid reportingtier accrualaccounting ///
				endofyeard~h  allotherin~e  costofserv~n  interestpaid  otherinves~e  totalliabi~y  gainonprop~n  debtorsand~s  accumulate~a  materialex~1 ///
				percentage~s  allothersh~s  costoftrad~s  inventory     restricted~s  allothergr~p  othercompr~e  moneyheldo~s  accumulate~s   ///
				annualretu~d  avgallpaid~k  depreciation  investments   salariesan~s  servicetra~e  totalcompr~e  moneyowedt~i  reserves      materialex~2 ///
				allcurren~ts  avgallvolu~k  donationsk~a  land          status        maraefunds    comprehens~o  othercurre~s  minorityin~t  ///
				allcurren~es  avgnovolun~k  endowmentf~s  membership~s  totalassets   maoritrust~d  receiptsfr~s  propertypl~t  otherresou~s  materialex~3 ///
				allnoncur~ts  bequests      generalacc~s  netsurplus~r  totalequity   otherreven~t  receiptsof~s  intangible~s  moneypayab~y   ///	 
				allnoncur~es  buildings     govtgrants~s  newzealand~s  totalexpen~e  otherreven~s  purchaseof~s  investment~y  othercommi~s  materialex~4 ///
				allotherex~e  cashandban~s  grantspa~enz  numberoffu~s  totalgross~e  totalliabilities fundraisin~s  repayments~s  totalasse~es  guarantees	numberofparttimeemployees			///
				mainactivityname activitysummary mainbeneficiaryname mainsectorname activities areasofoperation beneficiaries sectors sourcesoffunds		///
				geog*


	gen date_register = date(dateregistered, "DMY")
	format date_register %td
	gen date_deregister = date(deregistrationdate, "DMY")
	format date_deregister %td
	gen date_annretdue = date(annualreturnduedate, "DMY")
	format date_annretdue %td
	gen date_financialpos = date(financialpositiondate	, "DMY")
	format date_financialpos %td	
	
	gen deregistered = 0
	replace deregistered = 1 if date_deregister!=. & date_deregister>=date_register
	
	// Get rid of nonsense records
	drop if charityregistrationnumber=="."
	drop if date_financialpos ==.
	drop if year(date_financialpos)>=2020
	
	gen areaop = max(geog1, geog2, geog3, geog4, geog5, geog6, geog7, geog8, geog9, geog10)
	label define areaop_lab 1 "Provincial" 2 "National" 3 "International"
				
	save "$path1\nz_annualreturn_`yr'_v1.dta", replace

}

	// Build panel data set

	use "$path1\nz_annualreturn_2019_v1.dta", clear
	gen year = 2019

	forvalues yr = 2007(1)2018 {

		append using "$path1\nz_annualreturn_`yr'_v1.dta", force
		replace year = `yr' if year==.
	}

	gen remy = year(date_deregister)
	gen deregevent = 0
	replace deregevent = 1 if date_deregister!=. & remy==year
		
	*encode charityregistrationnumber, gen(ccnum)
	rename charityregistrationnumber ccnum

	// Check for duplicate annual returns - this is assessed by charity, date, and key headline financial figures
	// Drop any duplicates
	duplicates report ccnum date_financialpos totalgrossincome totalexpenditure totalassets totalliabilitiesandequity, drop force	

	// Now look for duplicates with different financials, but the same date
	// Consider duplicate financial returns filed in the same month

	gen month_finpos = month(date_financialpos)
	gen fin_year = year(date_financialpos)
	duplicates report ccnum  month_finpos fin_year
	duplicates tag ccnum  month_finpos fin_year, gen(duptag)

	// In this case, keep the one filed latest
	bysort ccnum month_finpos fin_year: egen latestar = max(annualreturnid)
	drop if duptag>0 & latestar != annualreturnid


	// This leaves us with 814 duplicates by charity and year
	// These can be legitimate duplicates e.g. if a charity changed its financial year
	duplicates report ccnum  fin_year

	// Create a proportional weighting that can be used for partial financial years
	sort ccnum date_financialpos

	capture drop prevfinposdate
	gen prevfinposdate = date_financialpos[_n-1] if ccnum == ccnum[_n-1]
	format prevfinposdate %td

	capture drop propofyear
	gen propofyear = (date_financialpos - prevfinposdate)/365
	replace propofyear = . if propofyear >1.5

	rename id orgid

	bysort orgid: egen maxret = max(date_financialpos)
	gen latestreturn = maxret == date_financialpos
	
	
	// Derived variables
	/*
		For theoretical model (see Table 2 Lu et al., 2019):
		
			- Revenue diversification; need to ask Carolyn which fields I need. [DONE]
			- Donative vs commercial; dummy variable indicating majority of income from donative sources. [DONE]
			- Fundraising expenditure [DONE]
			- Staff costs [DONE]
			- Mean (median) income and expenditure over the period. [DONE]
			- Volunteer input (mean number of hours contributed by volunteers) [DONE]
			
			- Netsurplus (not in Lu et al., 2019 model but could be worth exploring)
		
		From income composition paper:
		
			- Important, majority, dominant sources etc.
			- Other measures.
	*/
	
	** Income 
	
	codebook totalgrossincome
	replace totalgrossincome = . if totalgrossincome < 0
	rename totalgrossincome itotal
	
	bys ccnum: egen mninc = mean(itotal)
	bys ccnum: egen mdinc = median(itotal)
	l ccnum fin_year itotal mninc mdinc in 1/200
	foreach var in mninc mdinc {
		replace `var' = round(`var', 1)
	}
	
	
	** Expenditure
	
	codebook totalexpenditure
	replace totalexpenditure = . if totalexpenditure < 0
	rename totalexpenditure etotal
	
	bys ccnum: egen mnexp = mean(etotal)
	bys ccnum: egen mdexp = median(etotal)
	l ccnum fin_year etotal mnexp mdexp in 1/200
	foreach var in mnexp mdexp {
		replace `var' = round(`var', 1)
	}
	/*
		Create log and categorical (by reporting thresholds) versions.
	*/
	
		foreach var in mninc mdinc mnexp mdexp {
			gen `var'_ln = ln(`var' + 1)
		}
		
	
	** Debt level and investment income
	/*
		Speak to Carolyn about operationalising these a la Lu et al. (2019).
	*/
	
	
	** Operating margin
	
	codebook netsurplusdeficitfortheyear
	rename netsurplusdeficitfortheyear opmargin
	sum opmargin, detail
	hist opmargin, norm percent scheme(s1mono)
	/*
		Come back to this: an important variable but not sure how best to operationalise it for the cross-sectional analysis.
	*/
	
	
	** Donations
	
	codebook donationskoha
	replace donationskoha = . if donationskoha < 0
	rename donationskoha donations
	label variable donations "Income raised from donations"
	
		// Calculate ratio of donations to total income
		
		gen don_share = donations / itotal // lots of missing data, most of which are fine (i.e. itotal==0), some are puzzling...
		hist don_share, percent norm scheme(s1mono)
		replace don_share = . if donations > itotal
		l ccnum fin_year itotal donations don_share if don_share==.

		gen don_maj = 0 if don_share!=.
		replace don_maj = 1 if don_share > .50 & don_share!=.
		tab don_maj
		label variable don_maj "Derives majority of income from donations"
		label variable don_share "Share of total income derived from donations"
		
		// Calculate average level of donations and share
		
		bys ccnum: egen mndon_share = mean(don_share)
		bys ccnum: egen mddon_share = median(don_share)
		gen mndon_maj = 0 if mndon_share!=.
		replace mndon_maj = 1 if mndon_share > .50 & mndon_share!=.
		gen mddon_maj = 0 if mddon_share!=.
		replace mddon_maj = 1 if mddon_share > .50 & mddon_share!=.

		tab1 mndon_maj mddon_maj
		label variable mndon_maj "Derives majority of income from donations - on average (mean)"
		label variable mndon_share "Share of total income derived from donations - on average (mean)"
		label variable mddon_maj "Derives majority of income from donations - on average (median)"
		label variable mddon_share "Share of total income derived from donations - on average (median)"
		
	
	** Revenue diversification
	/*
		Index of five income variables:
			- donations
			- membership fees
			- receipts from goods and services
			- investment income
			- other income
			
		To calculate the index: first, divide every revenue source by total revenue. Second, square all ratios. 
		Third, add. Fourth, subtract this value from 1 to rescale from 0 (less diversified) to 1 (more diversified). 
	*/
		
	foreach var in membershipfees donations otherinvestmentincome servicetradingincome allotherincome {
		codebook `var'
		replace `var' = . if `var' < 0
		sum `var', detail
	}
	
	capture drop inc_diverse
	gen inc_diverse =  1 - ((donations/itotal)^2 + (otherinvestmentincome/itotal)^2 + ///
		(servicetradingincome/itotal)^2 + (membershipfees/itotal)^2 + (allotherincome/itotal)^2)
	inspect inc_diverse
	replace inc_diverse = . if inc_diverse < 0
	histogram inc_diverse, percent norm scheme(s1mono)
	sum inc_diverse, detail	
	label variable inc_diverse "Revenue diversification index - 0 (less diversified) to 1 (more diversified)"
	
		// Do some checks
		
		egen rowinc = rowtotal(membershipfees donations otherinvestmentincome servicetradingincome allotherincome)
		l ccnum fin_year itotal rowinc in 1/500
		/*
			Combining the five sources does not equal total income for many charities (it does for some?).
			
			Speak to Carolyn.
		*/
		
		// Calculate average level of inc diversification
		
		bys ccnum: egen mninc_diverse = mean(inc_diverse)
		bys ccnum: egen mdinc_diverse = median(inc_diverse)
		label variable mninc_diverse "Revenue diversification index - on average (mean)"
		label variable mdinc_diverse "Revenue diversification index - on average (median)"

	
	** Employee compensation
	
	codebook salariesandwages
	replace salariesandwages = . if salariesandwages < 0
	rename salariesandwages empcomp
	label variable empcomp "Employee compensation costs"
	
		// Calculate ratio of employee compensation to total expenditure
		
		gen empcomp_share = empcomp / etotal
		hist empcomp_share, percent norm scheme(s1mono)
		replace empcomp_share = . if empcomp > etotal
		
		// Calculate average level of employee compensation to total expenditure
		
		bys ccnum: egen mnempcomp_share = mean(empcomp_share)
		bys ccnum: egen mdempcomp_share = median(empcomp_share)
		label variable mnempcomp_share "Share of expenses accounted for by staff costs - on average (mean)"
		label variable mdempcomp_share "Share of expenses accounted for by staff costs - on average (median)"
	
	
	** Fundraising expenditure
	
	codebook fundraisingexpenses // only exists for a subset of charities
	replace fundraisingexpenses = . if fundraisingexpenses < 0
	rename fundraisingexpenses funexp
	label variable funexp "Fundraising expenses"
	
		// Calculate ratio of fundraising costs to total expenditure
		
		gen funexp_share = funexp / etotal
		hist funexp_share, percent norm scheme(s1mono)
		replace funexp_share = . if funexp > etotal

	
	** Volunter and staff hours/numbers
	
	codebook avgallvolunteerhoursperweek avgallpaidhoursperweek avgnovolunteersperweek numberoffulltimeemployees numberofparttimeemployees
	foreach var in avgallvolunteerhoursperweek avgallpaidhoursperweek avgnovolunteersperweek numberoffulltimeemployees numberofparttimeemployees {
		replace `var' = . if `var' < 0
	}
	rename avgallvolunteerhoursperweek volhours
	rename avgallpaidhoursperweek paidhours
	rename avgnovolunteersperweek voltotal
	rename numberoffulltimeemployees empft
	rename numberofparttimeemployees emptotal
	label variable volhours "Average number of weekly hours contributed by volunteers"
	label variable paidhours "Average number of weekly hours contributed by staff"
	label variable voltotal "Average number of weekly volunteers"
	label variable emptotal "Number of staff (full-time and part-time)"
	label variable empft "Number of full-time staff"
	
		// Calculate averages over annual returns
		
		foreach var in volhours paidhours voltotal empft emptotal {
			bys ccnum: egen mn`var' = mean(`var')
			bys ccnum: egen md`var' = median(`var')
			replace mn`var' = round(`var', 1)
			replace md`var' = round(`var', 1)
		}
	
	
	** Main source of funds
	/*
		Does this change over time?
	*/
		
sort ccnum fin_year
save "$path1\nz_annualreturns_2007-2019_v1.dta", replace
	
	
	// Save a version containing only latest annual return and summary measures (e.g. mdinc)

	use "$path1\nz_annualreturns_2007-2019_v1.dta", clear
		
		keep if latestreturn==1
		keep ccnum itotal etotal mninc* mdinc* mnexp* mdexp* volhours paidhours voltotal empft emptotal ///
			mnvolhours mnpaidhours mnvoltotal mnempft mnemptotal mdvolhours mdpaidhours mdvoltotal mdempft mdemptotal empcomp empcomp_share mnempcomp_share ///
			funexp funexp_share	fin_year remy sourcesoffunds areaop don_maj mndon_maj don_share mndon_share inc_diverse mninc_diverse
		duplicates report ccnum
		duplicates drop ccnum, force
	
	sort ccnum
	save "$path1\nz_annualreturns_latest.dta", replace



/** 2. Merge data **/

** Trustees **

use $path1\nz_trustees_20190909.dta, clear

merge m:1 orgid using $path1\nz_charreg_merge_20190909.dta, keep(match master) // some unmatched observations
distinct orgid if _merge==1
rename _merge cr_merge


	// Derived variables

	egen pickone = tag(orgid) // create an identifier used to select one observation per charity
	
	** NOT WORKING **
	gen applen = .
	replace applen = resdate - appdate if resdate!=. // number of days served on the board if resigned
	replace applen = (date("18092019", "DMY") - appdate) if applen==. // number of days served on the board if still active
	/*
		In order to calculate length of appointment for current trustees, I need to identify most recent annual return year for
		a charity - do so after merging with charity register/annual returns data.
	*/
	
	
	bys orgid: gen orgtt = _N // total number of trustees
	bys orgid: egen orgct = total(ct) // total number of current trustees
	bys orgid: egen orgts = total(applen) // total length of service
	bys orgid: egen orgcs = total(applen) if ct==1 // current length of service
	/*
		See Benefacts analysis to see if I've calculated the final variable correctly.
	*/
	
	label variable orgtt "Total number of trustees"
	label variable orgct "Total number of current trustees"
	label variable orgts "Total length of service"
	label variable orgct "Total length of service - current trustees"
	
	// Save summary version for merging with charity register
	
	preserve
		keep if pickone
		keep orgid orgtt orgct orgts orgct
		sort orgid
		duplicates report orgid
		sav $path1\nz_trustees_merge_20190909.dta, replace
	restore
	
sort orgid tid
sav $path3\nz_trustees_20190909.dta, replace


** Charity Register **

use $path1\nz_charreg_20190909_v1.dta, clear

	// Trustees

	sort orgid
	merge 1:1 orgid using $path1\nz_trustees_merge_20190909.dta, keep(match master)
	drop _merge


	// Activities

	sort actid
	merge m:1 actid using $path3\nz_activities_20190909.dta, keep(match master)
	drop _merge


	// Sectors

	sort secid
	merge m:1 secid using $path3\nz_sectors_20190909.dta, keep(match master)
	drop _merge


	// Beneficiaries

	sort benid
	merge m:1 benid using $path3\nz_beneficiaries_20190909.dta, keep(match master)
	drop _merge


	// Annual Returns
	/*
		STILL WORK TO DO HERE:
		
		We want the following variables:
			- latest annual return year (allows us to calculate age)
			- latest or mean annual income (allows us to calculate size)
			- source of funds (latest or summary/aggregate measures)
			- area of operation (latest or summary/aggregate measures)
	*/

	sort ccnum
	merge 1:1 ccnum using $path1\nz_annualreturns_latest.dta, keep(match master)
	rename _merge ar_merge

	// Source of Funds
	/*
	sort srcid
	merge m:1 srcid using $path3\nz_sources_20190909.dta, keep(match master)
	drop _merge
	*/

	// Area of Operation
	/*
	sort aooid
	merge m:1 aooid using $path3\nz_aoo_20190909.dta, keep(match master)
	drop _merge
	*/

	
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
	
	tab1 actid benid secid
	gen activity = actid
	recode activity 11/max=11
	
	gen beneficiary = benid
	recode beneficiary 12/max=12
	
	gen sector = secid
	recode sector 19/max=19
	/*
		Collapse all of the "Other - " values for each variable.
		
		Don't forget to label values and variables.
	*/
	/*
	gen source = srcid
	recode source 10/max=10

	gen areas = aooid // Need to use `labmask' to label values
	gen aoo_cont = aooid
	recode aoo_cont 1=1 2=2 3=3 8=4 14=5 16=8 18=7 *=. // is it fair to label all other values as missing?
	*/
	
	** Density 
	/*
		By registration year, count the number of active charities per 10,000 residents.
	*/
	
	
	** Age
	/*
		This is really 'years registered'.
	*/
	
	gen orgage = .
	replace orgage = fin_year - regy if deregistered==0
	replace orgage = remy - regy if deregistered==1
	tab orgage
	l ccnum regy remy fin_year orgage deregistered in 1/100

	
	** Size
	
	sum mninc*
	
	
	// Final checks
	/*
		Look at missing data for dependent variable.
		Look at registration status by registration year and missing data for remy.
	*/
	
	
	
compress
datasignature set
sav $path3\nz_charreg_analysis_20190910.dta, replace
