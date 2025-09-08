
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
 