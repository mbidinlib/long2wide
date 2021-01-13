# long2wide

Stata program that converts long dataset to wide

## Overview

Data officers/Managers might want to convert a dataset with repeat groups from long to wide 
This stata program de-identify data and labels some variables

## installation(Beta)

```stata
net install shortlist, all replace ///
	from("https://raw.githubusercontent.com/mbidinlib/long2wide/master/ado")
```

## Syntax

```stata

 long2wide , 					///
	folder(folder) 				///
	master(master_data) 		 	///
	outfolder(output_folder_path) 		///
	outfile( wideoutput file name) 		///
	key(key var name) 			///
	childkey(var name for child key)	///
	parentkey(var name for parent key) 	///
	dropextranum(drop_extra) 		///
	dropextraname( drop_extra)

```

### Folder:
	Folder path for all raw data files (.dta)
### Master
	name of the master data set
### Outfolder
	Folder in shich all output files would be stored. This should be empty	
### Outfile
	name of the final wide dataset		
### key
	Specify the key variable if different
### childkey
	specify the child key  variable if different
### Parentkey
	Specify the Parent key variable if different
### Dropextranum
	Assuming you want to drop extra unneccesary variables in a particular repeat group,specify minimum number of observations required to drop all missing variables in data
### Dropextraname
	Specify a repeat group dataset for which variables with all missing observations would be dropped


