// Draw a sample of Canadian charities for dissolution analysis

import delimited .\data_raw\20180517\canada_register_20180517.csv, clear
drop v13

gen statusdate = date(effectivedateofstatus, "YMD")
gen eligible = charitystatus=="Registered" | statusdate>=date("20100101", "YMD")
tab eligible

set seed 1978

sample 8, by(charitystatus)

tab charitystatus

export delimited .\data_raw\20180517\canada_register_sample_20180517.csv, replace
