
cd .. 
global data "raw_data\ConvenioMarco/transacciones"
global data_int "interm_data/transac"
global data_m "interm_data\transac\monthly_trans"
global figures "C:\Users\lucas\CH_Research Dropbox\Lucas Schmitz\Apps\Overleaf\Second year paper\figures\price_dispersion"
*log using "transacciones_import.log", text replace

**# Bookmark #1 use the data 

use  "$data_int/transacciones_all_cleaned.dta", clear
drop conveniomarco idconveniomarco estadooc especificaciondelcomprador nombreoc nombreproducto producto moneda direccionunidadcompra razonsocialcomprador comunadelproveedor observaciones totalineaneto  descuentoglobaloc subtotaloc impuestos montototalocneto montototaloc cargosadicionalesoc

tab regionu	
tab  tipodeproducto

// data cleaning 
	replace preciounitario = preciounitario / 1e6
	replace tipodeproducto = "sedán" if strmatch(lower(modelo), "*sedan*")
	replace tipodeproducto = "sedán" if strmatch(lower(modelo), "*sdn*")



// generate region codes and obs per code 
encode regionunida, gen(region_num)
encode tipodeproducto, gen(producto_num) // TIPO PRODUCTO IS MISLEADING, E.G. SOME AUTOMOVIL ARE ACTUALLY SEDAN (E.G. CODIGOOC = 2945-323-cm17)
egen region_count = count(preciounitario), by(region_num)
egen producto_count = count(preciounitario), by(producto_num)

	
gen price_capped = min(preciounitario, 37) 
graph box price_capped if region_count >= 120 & producto_count >= 120, ///
    over(region_num) over(producto_num) asyvars ///
    title("Price Distribution by Region and Product Type") ///
    ytitle("Unit Price(millions of CLP)")  legend(on) 

graph export "$figures/pricedistribution_over_regiontype.png", replace


graph box preciounitario if region_count >= 120 & producto_count >= 120, ///
    over(region_num) over(producto_num) asyvars ///
    title("Price Distribution by Region and Product Type") ///
    ytitle("Unit Price(millions of CLP)")  legend(on) 	yscale(range(0 40))
graph export "$figures/pricedistribution_over_regiontype(2).png", replace

 
// clean modelo var
gen modelo_cleaned = modelo 
order modelo_clea*, a(modelo)
 
 local str_part "td l r d \b"
foreach word of local str_part{ 
	replace modelo_cleaned = regexr(modelo_cleaned, "[0-9]\.[0-9]`word'", "")
}
 
local to_remove "new 2wd 4wd at mt cc ltz lt tl 4x4 4x2 nuevo sedan sdn 2ab ad all m se dx sr \(wide\) sense work doble rb iii d/c dc cd cr nb wf gasolina xe lujo ls aa" // maybe add 'grand'
foreach word of local to_remove {
	local pattern = "\b`word'\b"
	replace modelo_cleaned = regexr(modelo_cleaned, "`pattern'", "")
}
replace modelo_cleaned = regexr(modelo_cleaned, "[0-9][0-9][0-9][0-9]", "")
replace modelo_cleaned = subinstr(modelo_cleaned, "dmax", "d-max", .)
replace modelo_cleaned = strtrim(word(modelo_cleaned, 1) + " " + word(modelo_cleaned, 2))

order modelo_clea*, a(modelo) 
replace modelo_cleaned = strtrim(itrim(modelo_cleaned))


/// create comparisons for similar productos 
	egen prod_def = group(tipodeproducto marca nrolicitacionpublica) 
	bysort prod_def: gen num_prod = _N 
	egen prod_def2 = group(modelo_cleaned nrolicitacionpublica) 
	bysort prod_def2: gen num_prod2 = _N 
	egen prod_def3 = group(modelo nrolicitacionpublica) 
	bysort prod_def3: gen num_prod3 = _N 
save  "$data_int/temp.dta", replace
use  "$data_int/temp.dta", clear

summ num_prod2
order prod_def* num_prod*


reghdfe preciounitario, abs(i.prod_def2) resid
predict predicted_value
predict error, residuals
bysort prod_def2: egen avg_p = mean(preciounitario)
gen price_dev = error/avg_p 
histogram error, name(a, replace)
histogram price_dev if inrange(price_dev, -0.25, 0.25), name(b, replace) 
br if num_prod2 > 10

 graph box price_dev if inrange(price_dev, -0.25, 0.25), over(region_num, sort(1) label(angle(90))) ///
    ytitle("Price Deviation from Product Mean") legend(off) ///
    title("Distribution of Price Deviations by Region") ///
    subtitle("After controlling for vehicle model") ///
    note("Positive values indicate prices are higher than the product's average. Deviations taken from the mean of prices of sales of the same model.")
graph export "$figures/Pdeviations_over_region.png", replace

graph bar (mean) price_dev, over(region_num, sort(1) descending label(angle(90))) ///
    ytitle("Average Price Deviation (%)") ///
    title("Average Price Deviation by Region") ///
    subtitle("Deviations taken from the mean of prices of sales of the same model.")
graph export "$figures/Pdeviations_over_region(2).png", replace


// finer model def 
bysort prod_def3: gen first_obs = (_n == 1) 
histogram num_prod3 if first_obs
drop if num_prod3 < 5 


reghdfe preciounitario, abs(i.prod_def3) resid
predict predicted_value3
predict error3, residuals
bysort prod_def3: egen avg_p3 = mean(preciounitario)
gen price_dev3 = error3/avg_p3 
histogram error3, name(c, replace)
histogram price_dev if inrange(price_dev, -0.25, 0.25), name(d, replace) 
br if num_prod3 > 10

 graph box price_dev3 if inrange(price_dev, -0.25, 0.25), over(region_num, sort(1) label(angle(90))) ///
    ytitle("Price Deviation from Product Mean") legend(off) ///
    title("Distribution of Price Deviations by Region") ///
    subtitle("After controlling for vehicle model") ///
    note("Positive values indicate prices are higher than the product's average. Deviations taken from the mean of prices of sales of the same model. We use the finest definition of vehicle model. ")
graph export "$figures/Pdeviations_over_region_fine.png", replace

graph bar (mean) price_dev3, over(region_num, sort(1) descending label(angle(90))) ///
    ytitle("Average Price Deviation (%)") ///
    title("Average Price Deviation by Region") ///
    subtitle("Deviations taken from the mean of prices of sales of the same model.")
graph export "$figures/Pdeviations_over_region_fine(2).png", replace


//tipo de producto: is at the auction level for example 1354436 and 1354439 are the same product but one is 