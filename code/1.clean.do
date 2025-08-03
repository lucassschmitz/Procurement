
cd .. 
global data "raw_data\ConvenioMarco/transacciones"
global data_int "interm_data/transac"
global data_m "interm_data\transac\monthly_trans"
global figures "C:\Users\lucas\CH_Research Dropbox\Lucas Schmitz\Apps\Overleaf\Second year paper\figures\price_dispersion"
*log using "transacciones_import.log", text replace

**# Bookmark #1
// Take the transactions from all the FA and keep only the ones related to vehicles and store them 
 

foreach y of numlist 2017/2025 {
    forvalues m = 1/12 {
        di as txt ">>> Processing `y'-`m'"
		
		capture confirm file "${data}/`y'/`y'-`m'.csv"
        if _rc {
            di as txt "*** File not found: ${data}/`y'/`y'-`m'.csv -- skipping"
            continue
        }
        
        import delimited using "${data}/`y'/`y'-`m'.csv", clear 
        //  data-cleaning          
		
		*rename vars to avoid tildes 
    	foreach var of varlist _all {
        local newname = "`var'"
        local newname = subinstr("`newname'", "á", "a", .)
        local newname = subinstr("`newname'", "é", "e", .)
        local newname = subinstr("`newname'", "í", "i", .)
        local newname = subinstr("`newname'", "ó", "o", .)
        local newname = subinstr("`newname'", "ú", "u", .)
        if "`newname'" != "`var'" {
            rename `var' `newname'
        }
		}
		
		*convert vars to lower case 
    	ds, has(type string)
    	foreach var of varlist `r(varlist)' {
    		replace `var' = ustrlower(`var')
    	}
	
		capture rename totalneaneto totalineaneto  // for 2022-10
		capture rename nrolicitacinpblica nrolicitacionpublica
		capture drop v1

		*tag observations to keep 
    	gen tag1 = strmatch(conveniomarco, "*vehículos*")
    	gen tag2 = inlist(nrolicitacionpublica, "2239-20-lp13", "2239-4-lr17", "2239-5-lr21", "2239-8-lr23")
    	generate tag3 = strmatch(nombreproductoonu, "*vehículos*")
    	
    	 order tag1 tag2 tag3
    	
    	tab tag1 tag2 // tag1 is broader, e.g. includes some FA for leasing and complementary services like "2239-10-lp14" and "2239-22-lr15"
    	tab tag1 tag3 	
    	keep if tag1 + tag2 + tag3 > 0 // broad definition
    	
	
		* standarization
	destring idconveniomarco cantidad preciounitario totalineaneto descuentoglobaloc subtotaloc montototalocneto idgrancompra impuestos montototaloc cargosadicionalesoc, force replace

		tostring comunadelproveedor, replace
		tostring modelo, replace 
		
		drop formadepago
		
        // -----------------------------------
		save "$data_m/`y'-`m'", replace
    }
}

**# Bookmark #2
// join the files for the different months. 

clear
tempfile master
save `master', emptyok

 foreach y of numlist 2017/2025 {
    forvalues m = 1/12 {
		di as txt ">>> Processing `y'-`m'"
        capture confirm file "${data_m}/`y'-`m'.dta"
        if _rc continue
		
		
		// load cleaned file and convert entcode_comprador to numeric
        use "${data_m}/`y'-`m'.dta", clear
        destring entcode_comprador idproductocm orgcode_comprador, force replace
		
		
		capture rename raznsocialcomprador razonsocialcomprador
		capture rename direccinunidadcompra direccionunidadcompra
		capture rename reginunidaddecompra regionunidaddecompra
		capture rename institucin institucion
		capture rename regindelproveedor regiondelproveedor
		capture rename especificacindelcomprador especificaciondelcomprador
		capture rename fechaenvooc fechaenviooc
		
        // save temp and append
        tempfile tmp
        save `tmp'
        use `master', clear
        append using `tmp'
        save `master', replace

     }
}

save "$data_int/transacciones_all.dta", replace
 
 
**# Bookmark #3 sample selection 
 
use "$data_int/transacciones_all.dta", replace

	// select only purchases 
	tab nombreproductoonu
	tab nrolicitacionpublica

	keep if tag2
	tab nombreproductoonu

	drop if strmatch(nombreproductoonu, "*repara*") | strmatch(nombreproductoonu, "*manten*") | strmatch(nombreproductoonu, "*arrien*")

	tab tag1
	br if tag1 == 0 
	drop if tag1 == 0 

	tab tag2
	tab tag3
	br if tag3 == 0 
	drop tag*

	count if montototalocneto < 1e6
	br if montototalocneto < 1e6

	// select only cars/small vehicles 
	tab nombreproductoonu
	drop if strmatch(nombreproductoonu, "*camio*") | strmatch(nombreproductoonu, "*excava*")  | strmatch(nombreproductoonu, "*nivel*")  
	tab nombreproductoonu
	keep if strmatch(nombreproductoonu, "*culos*")  | strmatch(nombreproductoonu, "*autom*")
	drop if strmatch(nombreproductoonu, "*pol*" )
	
	// change region vars 
	replace regionunidaddecompra = "o'higgins" if regionunidaddecompra == "lib. gral. bdo. o'higgins"
	replace regionunidaddecompra = "magallanes" if regionunidaddecompra == "magallanes y antártica"
	replace regionunidaddecompra = "arica" if regionunidaddecompra == "arica y parinacota"

save "$data_int/transacciones_all_cleaned.dta", replace

**# Bookmark #4 use the data 

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

//tipo de producto: is at the auction level for example 1354436 and 1354439 are the same product but one is 