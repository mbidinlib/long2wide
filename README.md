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

 long2wide , ///
	folder(folder path for dta files) 	///
	master(master dataset name) 		///
	outfile(wide output file name) 		///
	outfolder(folder path for output files) ///
	outfile( wideoutput file name) 		///
	key(key var name) 			///
	childkey(var name for child key)	///
	parentkey(var name for parent key) 	///
	dropextranum(real) 			///
	dropextraname(str)

```


