# Mission Accomplished? A Cross-national Examination of Charity Dissolution

## Data Analysis

The sections referred to below are clearly marked in the respective analysis syntax file:
	* ma_nz_data_analysis_20190909.do
	
1. Sign up for an academic account on Github. DMD will then add you to the project repository containing the do files, paper, literature etc.
2. Conduct the following analyses for New Zealand:
	* Investigate observations with missing data across our dependent and independent variables i.e. differences in summary stats/distributions for three subpopultions: whole sample, those where filers==1, and those where nomiss==1
	* Section 2, Descriptive Analysis:
		* Produce a paragraph and table summarising the characteristics of the sample across categories of our outcomes; add the results to the following document: ma_nz_sample_summary_stats_20191107.docx
	* Section 3, Statistical Modelling:
		* Re-run the logit and mlogit models, and update the results in the following document: ma_nz_logit_results_2090924.docx
		* Perform some sensitivity analysis on the logit and mlogit models: try a different functional form of ```orgage``` (called ```orgage_dum```) and some of the other dummy variables (e.g. ```edsec```, ```cyp```); add ```inc_diverse``` to the models (this will drastically cut the sample size, don't worry); include interactions between ```orgtype``` and some of the other variables (start with ```orgsize```, ```maj_don``` and ```gov```). See whether these interactions are statistically significant.

Completion date for NZ analysis: 13/11/2019
