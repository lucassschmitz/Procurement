else if c(username) == "lucas" {
	global root = "C:\Users\lucas\OneDrive - Yale University\Documents\GitHub\2nd-year-paper\interm_data"
	global output = "C:\Users\lucas\Dropbox\Apps\Overleaf\Second year paper\figures\bunching"
	capture confirm file $root
}

import excel "$root\CM_auctions\auctions_processed.xlsx", sheet("Sheet1") firstrow clear


   
 
rddensity normalized_score, c(0) p(2) plot // 0.5097
rddensity normalized_score, c(0) nomasspoints // 0.57

keep if normalized_score >= -.4 & normalized_score <= .4
rddensity normalized_score, c(0) p(2) plot // 0.028
//rddensity normalized_score, c(0)  plot // 0.028
graph export "$output/cattaneo.png", replace


rddensity normalized_score, c(0) nomasspoints // 0.22

keep if normalized_score >= -.3 & normalized_score <= .3
rddensity normalized_score, c(0) p(2) plot // 0.04
rddensity normalized_score, c(0) nomasspoints //0.0791

keep if normalized_score >= -.2 & normalized_score <= .2
rddensity normalized_score, c(0) p(2) plot //0.0823
rddensity normalized_score, c(0) nomasspoints // 0.14

keep if normalized_score >= -.1 & normalized_score <= .1
rddensity normalized_score, c(0) p(2) plot // 0.0912
rddensity normalized_score, c(0) nomasspoints // .0982