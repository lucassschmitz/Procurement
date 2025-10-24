/* want to test the rddensity command in Stata. The cutoff is 0.5 Create a simulation of N observations where x is distributed uniformly between 0 and 1, where x will be the distribtuion without manipulation. then create x1 where observations to the left of .5 can try to manipulate the system and increase their x1. 
Then use the test to detect manipulation */

 
clear
set seed 12345
local N = 4000

* 1. Create baseline uniform distribution (no manipulation)
set obs `N'
gen x = runiform()  // Uniform [0,1]

* 2. Create manipulated version
gen x1 = x  // Start with original
* Manipulation: Some units just below cutoff bunching to just above Those between 0.45 and 0.50 have 30% chance to manipulate
gen can_manipulate = (x >= 0.45 & x < 0.50)
gen does_manipulate = can_manipulate * (runiform() < 0.20)
* If manipulating, jump to just above cutoff (0.50 to 0.52)
replace x1 = 0.50 + runiform() * 0.02 if does_manipulate == 1
count if does_manipulate == 1 // Count manipulators

* 3. Visualize the distributions and test 
twoway (histogram x, width(0.02) color(blue%30)) ///
       (histogram x1, width(0.02) color(red%30)), ///
		xline(0.5, lcolor(black) lwidth(thick)) ///
    legend(order(1 "No manipulation" 2 "With manipulation")) ///
    title("Distribution Comparison") ///
    xtitle("Running variable") ytitle("Density")

rddensity x, c(0.5) plot // Test on original (should find no manipulation)
rddensity x1, c(0.5) plot // test on manipulated (should detect manipulation)


* 4. More sophisticated manipulation patterns to test
clear
set obs `N'
gen x = runiform()

* Create different manipulation scenarios
* Scenario A: Sharp bunching just above
gen x_sharp = x
replace x_sharp = 0.501 + runiform()*0.01 if x >= 0.48 & x < 0.50 & runiform() < 0.4

* Scenario B: Smooth manipulation (harder to detect)
gen x_smooth = x
gen distance_to_cutoff = abs(x - 0.5)
gen prob_manip = exp(-distance_to_cutoff*20) * (x < 0.5)  // Probability decreases with distance
replace x_smooth = 0.50 + runiform()*0.03 if runiform() < prob_manip & x < 0.5

* Test all scenarios
foreach var in x_sharp x_smooth {
    di _n "Testing `var':"
    qui rddensity `var', c(0.5)
    di "T-statistic: " %6.3f r(test_T) "  P-value: " %6.4f r(test_p)
}

* 8. Power analysis: How much manipulation is needed to detect?
clear
set obs 100  // Number of simulations
gen manip_rate = (_n - 1) / 100  // Manipulation rate from 0% to 99%
gen detected = .

forvalues i = 1/100 {
    preserve
        quietly {
            clear
            set obs `N'
            gen x = runiform()
            gen x_test = x
            local rate = `i' / 100
            replace x_test = 0.50 + runiform()*0.02 if x >= 0.45 & x < 0.50 & runiform() < `rate'
            rddensity x_test, c(0.5)
        }
        local pval = r(test_p)
        restore
        replace detected = (`pval' < 0.05) if _n == `i'
}

twoway (line detected manip_rate, lcolor(navy) lwidth(medium)), ///
    title("Power to Detect Manipulation") ///
    xtitle("Manipulation Rate (share of eligible who manipulate)") ///
    ytitle("Detection Rate (at 5% significance)") ///
    ylabel(0(0.2)1) xlabel(0(0.1)1)
