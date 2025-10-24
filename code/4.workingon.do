
cd .. 



global raw_auction "raw_data\CM cars auction"
global int_auction "interm_data\CM_auctions" 
global figures "C:\Users\lucas\CH_Research Dropbox\Lucas Schmitz\Apps\Overleaf\Second year paper\figures\Stata_results"


////////////////////////////////////////////////////////////
**# Bookmark #1 
////////////////////////////////////////////////////////////

use "$int_auction\21_suv", clear 
append using "$int_auction\21_pickups"

tab EstadoFinal
gen selected = cond(EstadoFinal == "ADJUDICA", 1, 0) 
gen selected2 = cond(EstadoFinal == "ADJUDICA", 1, 0) if EstadoFinal != "No Adjudica"


encode Marca, generate(marca_num)
logit selected i.marca_num


// 1. Create a new dataset of means and confidence intervals by brand
collapse (mean) avg =selected (semean) se=selected  (count) n=selected , by(Marca)
gen lb = avg - invttail(n-1, .025)*se
gen ub = avg + invttail(n-1, .025)*se
keep if n > 5 // brands with certain level of participation 

save temp, replace 
use temp, clear
encode Marca, generate(marca_num)

* after your collapse + encode Marca -> marca_num
levelsof marca_num, local(levs)
local K : word count `levs'
disp `K'
twoway ///
    (bar  avg marca_num, base(0) barw(0.8)) ///
    (rcap ub lb marca_num), ///
    xlabel(1(1)`K', valuelabel angle(90) labsize(vsmall) noticks) ///
    xscale(range(0.5 `=`K'+0.5')) ///
    plotregion(margin(b+12)) ylabel(0(0.2)1) /// ///
    ytitle("Mean(selected) with 95% CI") xtitle("Brand") legend(off) ///
    name(bar_ci2, replace)
	
	
	 

// not possible to do it for the 2023 auction since the selection is at the firm level. 







//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////
**# Bookmark #2 Check 2021 price ceilings. IN PROGRESS
////////////////////////////////////////////////////////////


use "$int_auction\21_suv", clear 
append using "$int_auction\21_pickups"

drop Vehículo PrecioDespacho PrecioMacrozonaGama PuntajePrecio
rename RUT rutproveedor
rename Categoría tipodeproducto 
replace tipodeproducto = lower(tipodeproducto)
replace rutproveedor = lower(rutproveedor)



drop Cumplepreciomáximo EstadoAnterior 
br if (rutproveedor == "79.649.140-k" & tipodeproducto == "suv" & EstadoFinal == "ADJUDICA")

br if (rutproveedor == "81.318.700-0" & tipodeproducto == "suv" & EstadoFinal == "ADJUDICA")
br if (rutproveedor == "79.853.470-k" & tipodeproducto == "suv" & EstadoFinal == "ADJUDICA")
br if (rutproveedor == "96.981.470-6" & tipodeproducto == "suv" & EstadoFinal == "ADJUDICA")

tab Nombre if (tipodeproducto == "suv" & EstadoFinal == "ADJUDICA")
br
 

////////////////////////////////

import excel "$raw_auction\PROVEEDORES_-_Evaluación_CM_Vehículos_y_maquinarias.xlsx", sheet("EV ECONOMICA") cellrange(B3:AR4385) firstrow clear
 