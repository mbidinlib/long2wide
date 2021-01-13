
********************************
*!Mathew Bidinlib
* mbidinlib@poverty-action.org
********************************

cap program drop long2wide

program define long2wide 

 #d ;

syntax , [FOLDer(str)] 
		  [MASTer(str)] 
		  [OUTFolder(str)] 
		  [OUTFile(str)] 
		  [Key(name)] 
		  [CHILDkey(name)] 
		  [PARENTkey(name)] 
		  [DROPEXTRANum(real 0.1)] 
		  [DROPEXTRAName(str)]

	;
	#d cr


	clear all
	set more off

	qui{
	
	
		* Check if the master data is in stata format
		if !regexm("`master'", ".dta$") {
			di "`master'"
			noi di as err "Invalid data format: the master file should be a .dta file"
			exit
		}
		
		* Set Parent and child keys
		if "`parentkey'" != "" loc parent_key `parentkey'
		else loc parent_key "parent_key"
		
		if "`childkey'" != "" loc child_key `childkey'
		else loc child_key "child_key"


		* Save file names of child datasets in local
		*===========================================

		local files : dir "`folder'" files "*", respectcase
		local num	: word count `files'

		*====================================
		* Loop through long format datasets *
		*====================================

		forval i = 1/`num' {

			local file : word `i' of `files'

			if "`file'" ~= "`master'" {
				
				use "`folder'/`file'", clear
				
				cap drop setof*

				loca pkey = `parent_key'[1]
				loc num_pgrps = length("`pkey'") - length(subinstr("`pkey'", "[", "", .))

				gen p_key = substr(key, 1, strpos(key, "/") - 1)  				// Parent key of master
				
				*keep real variables of the repeat in a macro
				unab vs2 : _all 									
				unab rmove2 : p_key  `parent_key' key
				loc init_vars : list vs2 - rmove2 	    						// keep this initial var list

				gen pkey_cons = ""
				gen parent_name = ""
				gen pkey_last_ind = ""
				gen `parent_key'_n = `parent_key'
				gen `parent_key'_o = `parent_key'
				gen key_o  = key

				
				* loop if there is a nested repeat
				if `num_pgrps' > 0 {
				
					
					* loop over the number of nested repeat groups
					forval j = 1/`num_pgrps'{
						
						* Index that would be used to rename variables
						*=============================================
						gen pkey_ind`j' = substr(`parent_key', 					///
											strpos(`parent_key', "[")+ 1 ,    	///
											(strpos(`parent_key',"]")	 			///
											- strpos(`parent_key', "[") - 1) )
						
						replace pkey_cons =  pkey_cons + pkey_ind`j' + "_"
						
				
						replace parent_name = substr(`parent_key'_n,  ///
						strpos(`parent_key'_n, "/") + 1 ,    ///
						strpos(`parent_key'_n, "[") - strpos(`parent_key'_n, "/") -1 )
								
						replace `parent_key'_n = (subinstr(`parent_key'_n, "/", "", 1))
						replace `parent_key'_n = (subinstr(`parent_key'_n, "[", "", 1))

										
						* Last Index of parent
						replace pkey_last_ind =  pkey_ind`j'

						*Make replacements to allow for the next loop
						*=============================================
						replace `parent_key' = subinstr(`parent_key', "[", "",1)
						replace `parent_key' = subinstr(`parent_key', "]", "",1)
						replace key = subinstr(key, "[", "",1)
						replace key = subinstr(key, "]", "",1)
									
						* Create empty varibles for previous 
						* Levels of repeat (applicable to 
						* nested repeat
						*===================================
						unab vs2 : _all 									
						unab rmove2 : p_key pkey_* `parent_key' key  `parent_key'_o
						if `j' == 2 loc vs2: list vs2 - rn_vars2  	// remove first instance in second loop
						
						loc rn_vars2: list vs2 - rmove2 			// remove vars not needed
									 
					
						destring  pkey_ind`j', replace
						qui sum   pkey_ind`j'
						loc l_val`j'  `r(max)'
						
						foreach rvars of loc rn_vars2 {
							
							loc val_lab    `:val lab `rvars''
							loc type 		substr("`:type `rvars''",1,3)
							loc format 		`:format `rvars''
							*tostring `rvars', replace
							
							forval p = 1/`l_val`j''{
							
								cap	gen `rvars'_`p' = .
								cap confirm var  `rvars'_`p'
								if !_rc {
									if `type' == "str" 	tostring `rvars'_`p' , replace
									else 				label val `rvars'_`p' `val_lab'
									format `rvars'_`p' 	`format'
								}
							}	
								
							

								/*
								cap {
									if substr("`:type `rvars''",1,3) == "str" {
										gen  `rvars'_`p' = ""
									}
									else  gen `rvars'_`p' = .
									format `rvars'_`p' `:format `rvars''
								 }
								*/
							
							if `j' == 2 cap drop `rvars' 		// drop first level is there is a second level
						}
						
					
					}

				}	

				

				
				* Names exceeding 31 characters
				loc c_names ""
				loc n_names ""
				
				foreach bar of varl _all {
				
					if length("`bar'") > 29 {
						loc len  = strlen("`bar'")- 5
						loc nname = substr("`bar'", -`len',.)
						ren `bar' `nname'
						loc c_names = "`c_names'" + " `bar'"
						loc n_names = "`n_names'" + " `nname'"
					}
				}

				

				* get variables to rename for reshaping
				unab vs3 : _all 									
				unab rmove3 : p_key pkey* `parent_key' key parent_name `parent_key'_o key_o
				loc rn_vars3: list vs3 - rmove3 			// remove vars not needed

				
				* rename real variables for wide reshape
				foreach p of loc rn_vars3 {
					
					ren `p' `p'_
				
				}
				
					* last index (_?) of repeat
				gen mkey_ind = substr(key,strpos(key, "[")+ 1 ,    	///
							(strpos(key,"]") - strpos(key, "[") - 1) )		

				replace pkey_cons = pkey_cons + mkey_ind
				destring mkey_ind, replace
					
				
					* Get vars to reshape on
				unab vs : _all 									
				unab rmove : p_key  mkey_ind  parent_name `parent_key'_o pkey_last_ind key_o
				loc rn_vars: list vs - rmove 			// remove vars not needed


				
				* Reshape data
				*==============	
				reshape wide `rn_vars', i(p_key parent_name `parent_key'_o key_o) j(mkey_ind)
				
					
						if `num_pgrps' > 0 { 										// If the repeat is nested
					
							if `num_pgrps' == 2   loc indx "_*_*"
							else 			      loc indx "_*"
							
						*di "`init_vars'"
						
							foreach init  of loc init_vars {						// loop through the main variables in the repeat
								loc n_cons = 0
							
								loc keepvars "p_key parent_name `parent_key'_o key_o pkey_last_ind"
								foreach cons of varl pkey_cons* {					// lop through the number number of wide splits
									local n_cons `++n_cons'
									loc q = _N
								
									forval q = 1/`q' { 								// Loop through the entire observation
										loc consva = `cons'[`q']
										*di "`init'"  "`consva'" "`n_cons'"
									
										*set trace on 
										if "`consva'" != "" { 				
											qui replace `init'_`consva' = `init'_`n_cons' if `cons' == "`consva'"
											loc keepvars =  "`keepvars'" + " `init'`indx'"
										}
									
									}
								
								 }
								
							  }
						}
						
						
						else {
						
							unab keepvars : p_key `parent_key'_o key_o
							foreach lo of local  init_vars {
								
								loc keepvars = "`keepvars'" + " `lo'*"			
							
							}
							
						}
				
				
				cap keep `keepvars' `n_names'		
				
				* Take real parent key from nested parent key
				ren `parent_key'_o 	`parent_key'
				ren key_o			key
				
				* drop extra  variales for large unexpected repeats
				***************************************************
				
				if "`dropextranum'" !="" | "`dropextraname'" !="" {
					unab all : _all
					loc var_count : word count `all'

					if `var_count' > `dropextranum' | "`file'" == "`dropextraname'" {
					
						foreach var of varlist _all {
							capture assert( mi(`var'))
							 if !_rc {
								drop `var'
							 }
						 }
					}

				}
				
				*copy "${dir_hh_survey}/long/`file'"  "${dir_hh_survey}/long/successfull/`file'" , replace
				*rm "${dir_hh_survey}/long/`file'"
				
				* replace for each key
				gen _backward = -_n
				foreach p of varl _all {
					bys p_key (_backward): replace `p'= `p'[_n-1] if missing(`p')	
				}
				gsort -_backward
				drop _backward
				
				duplicates drop p_key, force


				save "`outfolder'/`file'", replace

				
			}
			
		}



		*===============================================
		* Loop through reshaped data for nested repeat *
		*===============================================

		copy "`folder'/`master'" ///
			 "`outfolder'/`master'" , replace

		use "`outfolder'/`master'", clear
		sort key
		tempfile masterfile
		save "`masterfile'", replace
		 
		local files : dir "`outfolder'" files "*", respectcase
		local num	: word count `files' 
		local num = `num' - 1

		noi di "Number of repeat groups: " _column(10) " `num'" 
		noi di "{hline}"

		forval i = 1/`num' {
	
			local file : word `i' of `files'
			
			if "`file'" != "`master'" {
				use "`outfolder'/`file'", clear
				
				ren key `child_key'
				ren p_key key
				
				noi di " merging repeat group # `i'"
				
				merge 1:m key using  "`masterfile'", nogen nonotes noreport
				sort key
				save "`masterfile'", replace
			}
			
		}		
		
		drop `parent_key' setof* `child_key'

		if "`outfile'" != "" {
			save "`outfolder'/`outfile'", replace
		}
	}
	
end
