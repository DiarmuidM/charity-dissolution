# Row fixer 
# Tom Wallace
# Created 07/05/2019
# Last updated - see GutHub history

# This function will fix the integrity erorrs caused by double quotes combining to escape commas and breaking columns up.
# This method is complicated and inelegant but works for most errors: 77% in nz_checkintegrity.py (51 down to 12), 96% in GrpOrgAllReturns (24 down to 1)m and 70% for vOfficerOrganisations 18030 to 5487. 
# It may be possible to reach 100% but this would be more likley to write corrupted data to the clean files (it would have a chance of joining the wrong columns to hit the right length).

# The errors all appear to be casued by unsanatised double quotes interacting with commas. But they are not consistent.
# All errors have a double quote at the end of the data in the last split column (the rightmost column). For example col1: 'This is an' col2: ' example"'
# Most errors have a white space character at the start of the rightmost column, as shown in the example - but some do not.
# Most errors have a double quote somewhere in the leftmost column but this moves arond and not all do - For example col1 'This is" an'
# Some errors stretch across more than 2 columns.

# How the fix below works;
# The code below will look for the trailing rightmost double quote with whitepsace column and join it with the column to it's left.
# It then checks if the column is now the correct length, if it is, it get's written as a fixed column.
# If it's still wrong it checks if it is just 1 place out, if it is it runs the join again (this fixes errors spread across 3 colums) and checks again, if now correct it get's written to the clean file.
# If it's out my more than one place, or the second join didn't fix it, the original (unmodified) column get's written to the error file.

#######Import packages#######
import re

#######Functions#######
def row_fixer(row, checklength):
	if len(row) == checklength: # If the row is the right legth just write it to the clean file
		fixed=True
		return row, fixed
	else: # If it's wrong...
		counter=0 # Initialise a counter
		for column in row: # for each column in the broken row, count until you find a string starting with a whitespace and ending with a double quote (a characteristic of most errors), then stop
			counter=counter+1
			searchpattern = re.compile('^ +.+"$') # Leading white space, anything, trailing double quote
			if searchpattern.search(column):
				break # counter now contains the column number of the broken column - can fix it by joining it with the one to the left
		front=counter-2 # the front column is 1 back from the coutned column which is 2 in python's odd way of handling ranges
		back=counter # back is just the counter number
		row1=row.copy() # This creates a copy of the list which isn't modifed by the join below - this unaltered copy can then be written to the error file if the fix fails
		row[front:back] = [''.join(row[front:back])] # Reform the row with the split column put back togethor.
		if len(row) == checklength: # Check the length of the modified row
			fixed=True
			return row, fixed
		else: # IF that didn't do it...
			if len(row) == checklength+1: # Check if it's just 1 out which means it's broken acorss 3 columns
				counter=0 # Run exactly the same join code as above
				for column in row: 
					counter=counter+1
					searchpattern = re.compile('^ +.+"$')
					if searchpattern.search(column):
						break #
				front=counter-2
				back=counter
				row[front:back] = [''.join(row[front:back])]
				if len(row) == checklength: # Check the length again
					fixed=True
					return row, fixed
			fixed=False
			return row1, fixed
