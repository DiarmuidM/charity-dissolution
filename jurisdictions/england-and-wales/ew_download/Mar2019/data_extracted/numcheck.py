#Tom Wallace
#10/4/19
#This counts the length of all of the data files

import pandas as pd

file_list = ['extract_acct_submit.csv','extract_aoo_ref.csv','extract_ar_submit.csv','extract_charity.csv','extract_charity_aoo.csv','extract_class.csv','extract_class_ref.csv', 
	'extract_financial.csv','extract_main_charity.csv', 'extract_name.csv', 'extract_objects.csv','extract_partb.csv','extract_registration.csv','extract_remove_ref.csv','extract_trustee.csv']

nums = []
for file in file_list:
	df = pd.read_csv(file, escapechar='\\', header=0, skip_blank_lines=True, na_values='')

	#df1 = df[df.isnull().any(axis=1)]
	#print(df1)

	df.dropna(inplace=True, how='all')

	#print(df)
	print(len(df))
	nums.append(len(df))
print('\n',nums)	
