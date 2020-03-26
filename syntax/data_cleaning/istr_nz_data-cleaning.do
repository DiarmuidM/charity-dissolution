// Prepare Analysis Dataset
// New Zealand Charity Data
// Created: 5 April 2018
// Edited: 19 April 2018

global path1 = "C:\Users\ar34\Dropbox\Academic\Academic-Research-Projects\gitreps\scrapeNZ"

//\analysis"

/* Define paths */
/*
include "C:\Users\mcdonndz-local\Desktop\github\paper-istr-2018\syntax\project_paths.doi"
*/


// ORGANISATION DATA

import delimited "$path1\rawdata\20180330\Organisations\nz_orgs_deregreasons_integrity.csv", clear

keep organisationid accountid name charityregistrationnumber dateregistered deregistrationdate deregistrationreasons establishedbyparliamentact excemptioncomment isincorporated organisational_type registrationstatus society_institution trustees_trust exemptions   grouptype groupid postaladdress_city postaladdress_country mainactivityid mainbeneficiaryid mainsectorid dereg_act dereg_reason

drop if organisationid==""
drop if name == ""
drop if charityregistrationnumber==""
drop if dateregistered==""

gen deregistered = deregistrationdate != "null"

duplicates report *
duplicates drop *, force

tab isincorporated
gen company = 0
replace company = 1 if isincorporated == "true"
drop isincorporated

tab organisational_type
gen orgtype = 0
replace orgtype = 1 if organisational_type == "Society or institution"
replace orgtype = 2 if organisational_type == "Trustees of a trust"
drop organisational_type

tab registrationstatus
gen registered = 0
replace registered = 1 if registrationstatus == "Registered"

save "$path1/analysis/organisationdetail.dta", replace

keep organisationid accountid name charityregistrationnumber dateregistered deregistrationdate  deregistered

save "$path1/organisationcore.dta", replace

// ANNUAL RETURNS DATA

global path_ar = "$path1\rawdata\20180330\GrpOrgAllReturns"

forvalues yr = 2007(1)2017 {

	di "Year: `yr'"

	import delimited "$path_ar/GrpOrgAllReturns_yr`yr'.csv_integrity_geog.csv", clear
	
	
	// Get rid of rows where the data has been corrupted
	tab endofyeardayofmonth, missing
	capture replace endofyeardayofmonth = "0" if endofyeardayofmonth==.
	destring endofyeardayofmonth, replace force
	drop if endofyeardayofmonth==.
	replace endofyeardayofmonth = . if endofyeardayofmonth==0

	// Make sure that all the rest of the financial variables are bytes
	quietly destring 	endofyeard~h  allotherin~e  costofserv~n  interestpaid  otherinves~e  totalliabi~y  gainonprop~n  debtorsand~s  accumulate~a  materialex~1 ///
				percentage~s  allothersh~s  costoftrad~s  inventory     restricted~s  allothergr~p  othercompr~e  moneyheldo~s  accumulate~s   ///
				annualretu~d  avgallpaid~k  depreciation  investments   salariesan~s  servicetra~e  totalcompr~e  moneyowedt~i  reserves      materialex~2 ///
				allcurren~ts  avgallvolu~k  donationsk~a  land          status        maraefunds    comprehens~o  othercurre~s  minorityin~t   ///
				allcurren~es  avgnovolun~k  endowmentf~s  membership~s  totalassets   maoritrust~d  receiptsfr~s  propertypl~t  otherresou~s  materialex~3 ///
				allnoncur~ts  bequests      generalacc~s  netsurplus~r  totalequity   otherreven~t  receiptsof~s  intangible~s  moneypayab~y   ///	 
				allnoncur~es  buildings     govtgrants~s  newzealand~s  totalexpen~e  otherreven~s  purchaseof~s  investment~y  othercommi~s  materialex~4 ///
				allotherex~e  cashandban~s  grantspa~enz  numberoffu~s  totalgross~e  fundraisin~s  repayments~s  totalasse~es  guarantees					///
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
				allotherex~e  cashandban~s  grantspa~enz  numberoffu~s  totalgross~e  fundraisin~s  repayments~s  totalasse~es  guarantees					///
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
				
	save "$path1/analysis/annualreturn_`yr'.dta", replace

}


// BUILD LONGITUDINAL FILE

use "$path1/analysis/annualreturn_2016.dta", clear
gen year = 2016

forvalues yr = 2008(1)2015 {

	append using "$path1/analysis/annualreturn_`yr'.dta", 
	replace year = `yr' if year==.
}

gen dyear = year(date_deregister)
gen deregevent = 0
replace deregevent = 1 if date_deregister!=. & dyear==year
	
encode charityregistrationnumber, gen(charityid)

// Check for duplicate annual returns - this is assessed by charity, date, and key headline financial figures
// Drop any duplicates
duplicates report charityid date_financialpos totalgrossincome totalexpenditure totalassets totalliabilitiesandequity, drop force	

// Now look for duplicates with different financials, but the same date
// Consider duplicate financial returns filed in the same month

gen month_finpos = month(date_financialpos)
gen year_finpos = year(date_financialpos)
duplicates report charityid  month_finpos year_finpos
duplicates tag charityid  month_finpos year_finpos, gen(duptag)

// In this case, keep the one filed latest
bysort charityid month_finpos year_finpos: egen latestar = max(annualreturnid)
drop if duptag>0 & latestar != annualreturnid


// This leaves us with 814 duplicates by charity and year
// These can be legitimate duplicates e.g. if a charity changed its financial year
duplicates report charityid  year_finpos

// Create a proportional weighting that can be used for partial financial years
sort charityid date_financialpos

capture drop prevfinposdate
gen prevfinposdate = date_financialpos[_n-1] if charityid == charityid[_n-1]
format prevfinposdate %td

capture drop propofyear
gen propofyear = (date_financialpos - prevfinposdate)/365
replace propofyear = . if propofyear >1.5

rename id organisationid

bysort organisationid: egen maxret = max(date_financialpos)
gen latestreturn = maxret == date_financialpos

save "$path1/analysis/annualreturns_2008-2016.dta", replace

use "$path1/analysis/annualreturns_2008-2016.dta", clear
keep if latestreturn==1
save "$path1/analysis/annualreturns_latest.dta", replace

// Analysis dataset

use  "$path1/analysis/organisationdetail.dta", clear

// merge 1:m organisationid using "$path1/analysis/annualreturns_2008-2016.dta" , gen(_mergfintag)
merge 1:m charityregistrationnumber using "$path1/analysis/annualreturns_2008-2016.dta" , gen(_mergfintag) keep(matched)

save  "$path1/analysis/linkedorg-fin.dta", replace



