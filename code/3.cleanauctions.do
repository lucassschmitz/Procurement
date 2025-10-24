
cd .. 



global raw_auction "raw_data\CM cars auction"
global int_auction "interm_data\CM_auctions" 
global figures "C:\Users\lucas\CH_Research Dropbox\Lucas Schmitz\Apps\Overleaf\Second year paper\figures\Stata_results"


**# Bookmark #0

// 2017 data 
import excel "$raw_auction\Planilla_General_Evaluación_-_ID_2239-4-LR17_(Publicación).xlsx", sheet("Ev_Compra_Subcat1+2") clear firstrow

// 	WE STILL DO NOT HAVE THE PRICE CEILINGS FOR 2017 

////////////////////////////////////////////////////////////
**# Bookmark #1 2021 pickup auctions 
////////////////////////////////////////////////////////////

// 2021 data 
import excel "$raw_auction\Planilla_de_adjudicación_CM_Vehículos_ID_2239-5-LR21_V.F..xlsx", sheet("Adjudicación Camionetas") cellrange(A1:L203) firstrow clear

/*
Pgm is the variable 'PrecioMacrozonaGama' in the 'Camionetas' sheet. 
*/

// gen vars 
replace Vehículo = lower(Vehículo)
gen Marca = word(Vehículo, 1)

egen aux4 = group(RUT Categoría Macrozona Gama )
bysort RUT Categoría Macrozona Gama: gen aux4_n = _n 
summ aux4_n
drop aux* 

tempfile adju_cami_21
save `adju_cami_21'	


import excel "$raw_auction\Planilla_de_adjudicación_CM_Vehículos_ID_2239-5-LR21_V.F..xlsx", sheet("Camionetas") clear firstrow

/*
-> the acceptance/rejection is at the firm/auction level-> see file with rules of the auction. 
Whenever there are multiple options only option 1 appears in the winner's sheet. 

Precio: at the RUT-Vehiculo level is the price of the car without including delivery
PrecioDespacho: Price of the car including delivery
PrecioMacrozonaGama: at the RUT-Macrozona-Gama level, it is the average of PrecioDespacho for a given firm within a Macrozona-Gama. 
*/ 


// destring vars
destring PrecioDespacho PrecioMacrozonaGama PuntajePrecio, force generate(PrecioDespacho_num PMacrozonaGama_num PuntajePrecio_num)

// check construction of 'PuntajePrecio' (score)  and  'PrecioMacrozonaGama'  
bysort Macrozona Gama: egen aux = min(PMacrozonaGama_num) 
gen score = 100*(aux/PMacrozonaGama_num) 
gen aux2 = abs(PuntajePrecio_num - score) 
count if aux2 > .01 & !missing(aux2) // 0 

bysort RUT Macrozona Gama: egen double aux3 = mean(PrecioDespacho_num)
gen aux4 = abs(aux3 - PMacrozonaGama_num)
count if aux4 > .01 & !missing(aux4) // 0 
drop aux* score

replace Modelo = lower(Modelo) 
replace Marca = lower(Marca) 
replace Versión = lower(Versión)
gen Vehículo = Marca + " " + Modelo + " " + Versión 

merge 1:1 RUT Vehículo Macrozona Gama using `adju_cami_21'	


tab Opción _merge // 'Opcion1' always merged, 'Opcion2' or 'Opcion3' never merged
drop _merge 

count if PrecioMacrozonaGama != Pgm & !missing(Pgm)
drop Pgm 

sort Macrozona Gama RUT Opción
replace EstadoFinal = EstadoFinal[_n-1] if Opción == "Opción2"
replace EstadoFinal = EstadoFinal[_n-2] if Opción == "Opción3"

save "$int_auction\21_pickups", replace 
  
 
////////////////////////////////////////////////////////////
**# Bookmark #2 2021 SUV auctions 
////////////////////////////////////////////////////////////

import excel "$raw_auction\Planilla_de_adjudicación_CM_Vehículos_ID_2239-5-LR21_V.F..xlsx", sheet("Adjudicación SUV") cellrange(A1:L221) firstrow clear


// gen vars 
replace Vehículo = lower(ustrnormalize(Vehículo, "nfd"))
replace Vehículo = ustrregexra(Vehículo, "([AEIOUaeiou])\p{M}+", "$1")
replace Vehículo = ustrnormalize(Vehículo, "nfc")

egen aux4 = group(RUT Categoría Macrozona Gama )
bysort RUT Categoría Macrozona Gama: gen aux4_n = _n 
summ aux4_n
drop aux* 

tempfile adju_suv_21
save `adju_suv_21'	


import excel "$raw_auction\Planilla_de_adjudicación_CM_Vehículos_ID_2239-5-LR21_V.F..xlsx", sheet("SUV") clear firstrow

// See the pickup case for an analysis/explaantion of the data. 

// destring vars
destring PrecioDespacho PrecioMacrozonaGama PuntajePrecio, force generate(PrecioDespacho_num PMacrozonaGama_num PuntajePrecio_num)

// check construction of 'PuntajePrecio' (score)  and  'PrecioMacrozonaGama'  
bysort Macrozona Gama: egen aux = min(PMacrozonaGama_num) 
gen score = 100*(aux/PMacrozonaGama_num) 
gen aux2 = abs(PuntajePrecio_num - score) 
count if aux2 > .01 & !missing(aux2) // 0 

bysort RUT Macrozona Gama: egen double aux3 = mean(PrecioDespacho_num)
gen aux4 = abs(aux3 - PMacrozonaGama_num)
count if aux4 > .01 & !missing(aux4) // 0 
drop aux* score


* remove accents only on vowels (áéíóú ü and uppercases), keep ñ as-is
foreach v in Marca Modelo Versión {
    replace `v' = lower(ustrnormalize(`v', "nfd"))
    replace `v' = ustrregexra(`v', "([AEIOUaeiou])\p{M}+", "$1")
    replace `v' = ustrnormalize(`v', "nfc")
}


gen Vehículo = Marca + " " + Modelo + " " + Versión 

merge 1:1 RUT Vehículo Macrozona Gama using `adju_suv_21'	


tab Opción _merge // 'Opcion1' always merged, 'Opcion2' or 'Opcion3' never merged
drop _merge 

count if PrecioMacrozonaGama != Pgm & !missing(Pgm)
drop Pgm 

sort Macrozona Gama RUT Opción
replace EstadoFinal = EstadoFinal[_n-1] if Opción == "Opción2"
replace EstadoFinal = EstadoFinal[_n-2] if Opción == "Opción3"

save "$int_auction\21_suv", replace 
 
////////////////////////////////////////////////////////////
**# Bookmark #3  Analysis 2021 auctions. 
////////////////////////////////////////////////////////////

use "$int_auction\21_suv", clear 
append using "$int_auction\21_pickups"


ds Marca Modelo Precio Versión PrecioDespacho PrecioMacrozonaGama PuntajePrecio Vehículo, not
browse `r(varlist)'

egen auction_id = group(Macrozona Categoría Gama)
gen selected = (EstadoFinal == "ADJUDICA") if EstadoFinal != "INADMISIBLE" // winning bid indicator

// Unadmisible stats
	gen unadmisible = (inlist(PuntajePrecio, "INADMISIBLE", "No Cumple"))
	tab unadmisible
	bysort auction_id: egen n_bidders = count(PMacrozonaGama_num)
	bysort auction_id: egen n_unadmisible = total(unadmisible)
	gen share_unad = n_unadmisible / n_bidders 
	bysort auction_id: gen first_bid = (_n == 1)
	 
	hist share_unad if first_bid, title("Share of unadmisible bids") note("Unadmisible bids are not scored, because the bidder did not satisfy one of the requirements of the tender documents.   ")
	graph export "$figures/auction2021_hist_shareunad.png", replace 

	hist n_unadmisible if first_bid, title("Number of unadmisible bids") note("Unadmisible bids are not scored, because the bidder did not satisfy one of the requirements of the tender documents.   ")
	graph export "$figures/auction2021_hist_NUnad.png", replace 

	drop unadmisible first_bid n_bidders n_unadmisible share_unad



keep if Opción == "Opción1" & !missing(selected)

bysort auction_id (PMacrozonaGama_num): gen aux = PMacrozonaGama_num if selected == 1 & selected[_n+1] == 0 
bysort auction_id (PMacrozonaGama_num): egen threshold = total(aux)  // last winner 
bysort auction_id (PMacrozonaGama_num): gen last_sel = 1 if selected == 1 & selected[_n+1] == 0   
bysort auction_id (PMacrozonaGama_num): egen N_selected = total(selected)
bysort auction_id (PMacrozonaGama_num): gen aux1 = PMacrozonaGama_num if selected == 0 & selected[_n-1] == 1 
bysort auction_id (PMacrozonaGama_num): egen threshold2 = total(aux1) //first looser   


bysort auction_id: gen first_bid = (_n == 1)

* Calculate auction-level statistics for standardization
bysort auction_id: egen auction_mean = mean(PMacrozonaGama_num)
bysort auction_id: egen auction_sd = sd(PMacrozonaGama_num)
bysort auction_id: egen auction_min = min(PMacrozonaGama_num)
bysort auction_id: egen auction_max = max(PMacrozonaGama_num)
gen auction_range = auction_max - auction_min
bysort auction_id: egen n_bidders = count(PMacrozonaGama_num)
gen share_sel = N_sel / n_bidders


// standarize price measures. 
gen precio_zscore = (PMacrozonaGama_num - auction_mean) / auction_sd
gen precio_zscore2 = log(PMacrozonaGama_num/auction_mean)  
gen precio_normalized = (PMacrozonaGama_num - auction_min) / auction_range
gen pct_above_min = ((PMacrozonaGama_num - auction_min) / auction_min) * 100
gen auction_cv = auction_sd / auction_mean
gen dist_to_win = abs(PMacrozonaGama_num - threshold)
gen relative_dist = dist_to_win/auction_mean 

* share of bidders selected 
summ share_sel
histogram share_sel if first_bid, title("Share of winners") /// 
	xtitle("Share of selected firms") /// 
	note("2021 FA, number of selected firms divided by total number of firms who bidded")
graph export "$figures/auction2021_hist_shareofwinners.png", replace 

* how competitive are the auctions 
histogram n_bidders if first_bid, title("Number of bidders") /// 
	xtitle("Number of bidders") note("2021 FA, number of bidding firms")
graph export "$figures/auction2021_hist_numberbidders.png", replace 

* Distance from winning bid 
gen relative_dist2 = min(.5, relative_dist) 
graph box relative_dist2, over(selected) note("0 = Losers, 1 = Winners") 
/* much more dispersion for loosers than for winners 
could be driven just by more non-selected firms than selected firms. 
*/

twoway (histogram precio_zscore if selected==1, fcolor(blue%40) width(0.25)) ///
       (histogram precio_zscore if selected==0, fcolor(red%40) width(0.25)), ///
       legend(order(1 "Winners" 2 "Losers")) ///
       title("Standardized Bid Distribution") xtitle("Z-score") /// 
	   note("2021 FA, bids are substracted the auction level mean and divided by their standard deviation")
graph export "$figures/auction2021_hist_bidsbywinnersorlosers.png", replace 

twoway (histogram precio_zscore2 if selected==1, fcolor(blue%40) ) ///
       (histogram precio_zscore2 if selected==0, fcolor(red%40) ), ///
       legend(order(1 "Winners" 2 "Losers")) ///
       title("Standardized Bid Distribution") xtitle("log(bid/mean(bid))") /// 
	   note("2021 FA, deviations from the mean bid of the same auction. ")
graph export "$figures/auction2021_hist_bidsbywinnersorlosers(2).png", replace 
 
graph box precio_zscore, over(selected) ///
    title("Price Dispersion: Winners vs Losers") ///
    ytitle("Standardized Price (Z-score)") ///
    note("0 = Losers, 1 = Winners, to standarize substracted mean and divided by SD ") 
graph export "$figures/auction2021_boxplot_bidsbywinnersorlosers.png", replace 

histogram auction_cv if first_bid ,  name("hist1", replace) ///
        title("Distribution of CV across Auctions") ///
        xtitle("Coefficient of Variation") 	width(0.02)
/* the degree of competitiveness measured by price dispersion vaires significantly */ 
graph export "$figures/auction2021_hist_CVacrossauctions.png", replace 



////////////////////////////////////////////////////////////
**# Bookmark #4  2023 auction
////////////////////////////////////////////////////////////

import excel "$raw_auction\PROVEEDORES_-_Evaluación_CM_Vehículos_y_maquinarias.xlsx", sheet("EV ECONOMICA") cellrange(B3:AR4385) firstrow clear

// cleaning 
tab Categoría
tab TipoProducto
keep if Categoría == "Vehículos Livianos y Medianos"
tab Modelo
drop Categoría RegiónRomano
egen auction_id = group(Nombre)
order auction_id
drop Nombre 
sort auction_id Ranking 

 
// Unadmisible stats
	gen unadmisible = (PuntajeTotal == "Inadmisible") 
	tab unadmisible
	drop unadmisible 

drop if abs(DESCUENTO) > 12

tab Adjudicaciónfinalreglamín5

// gen vars 
bysort auction_id: gen first_bid = (_n == 1)
bysort auction_id: gen n_bidders =  _N 
bysort auction_id: egen n_winners = total(Adjudicaciónfinalreglamín5 == "Adjudica")
gen share_sel = n_winners / n_bidders 

destring PuntajeTotal, gen(PuntajeTotal_num) force

gen selected = cond(Adjudicaciónfinalreglamín5 == "Adjudica", 1, 0 )

bysort auction_id: egen threshold = min(cond(selected, PuntajeTotal_num, .)) // lowest score that won. 

bysort auction_id: egen mean_score = mean(PuntajeTotal_num)
gen z_score = log(PuntajeTotal_num/ mean_score) 
gen z_score2 = log(PuntajeTotal_num/ threshold) 
gen dist_to_cutoff = abs(threshold - PuntajeTotal_num) 

tab EstadoEvAdmTec
drop if EstadoEvAdmTec == "Inadmisible" 

tab cumpleconDctos2y10 cumplecontiendafisicaenregi
drop TipoProducto Modelo Medida RegiónN RUT NombreFantasia ID_Oferta EstadoEvAdmTec


*Distribution of discounts
histogram DESCUENTO, title("Discount offered") xtitle("Discount (%)") 
graph export "$figures/auction2023_hist_discounts.png", replace 

* share of bidders selected 
summ share_sel
histogram share_sel if first_bid, title("Share of winners") /// 
	xtitle("Share of selected firms") /// 
	note("2023 FA, number of selected firms divided by total number of firms who bidded")
graph export "$figures/auction2023_hist_shareofwinners.png", replace 

* how competitive are the auctions 
histogram n_bidders if first_bid, title("Number of bidders") /// 
	xtitle("Number of bidders") note("2023 FA, number of bidding firms")
graph export "$figures/auction2023_hist_numberbidders.png", replace 

* Distance from winning bid 
graph box dist_to_cutoff, over(selected) note("0 = Losers, 1 = Winners") /// 
	ytitle("Distance to the threshold") 
graph export "$figures/auction2023_box_disttocutoff.png", replace 

*Distribution of threshold socre
histogram threshold if first_bid, title("Threshold score distribution") /// 
	xtitle("Lowest score among winners")
graph export "$figures/auction2023_hist_threshold.png", replace 

*Distribution scores
histogram PuntajeTotal_num,  title("Score distribution") 
graph export "$figures/auction2023_hist_scores.png", replace 

*Distribution scores by winning/loosing
twoway (histogram PuntajeTotal_num if selected==1, fcolor(blue%40)) ///
       (histogram PuntajeTotal_num if selected==0, fcolor(red%40)), ///
       legend(order(1 "Winners" 2 "Losers")) ///
       title("Score Distribution") xtitle("Score") /// 
	   note("2023 FA")
graph export "$figures/auction2023_hist_scorebywinnersorlosers.png", replace 

*Boxplot of scores by winning/loosing    
graph box PuntajeTotal_num, over(selected) ///
    title("Score Dispersion: Winners vs Losers") ///
    ytitle("Score") ///
    note("0 = Losers, 1 = Winners")
graph export "$figures/auction2023_boxplot_scorebywinnersorlosers.png", replace 
	
*distribution of percentual deviations from the mean 
twoway (histogram z_score if selected==1, fcolor(blue%40)) ///
       (histogram z_score if selected==0, fcolor(red%40)), ///
       legend(order(1 "Winners" 2 "Losers")) ///
       title("Standarized Score Distribution") xtitle("Score") /// 
	   note("2023 FA, log(score/ mean(score{same auction}))")
graph export "$figures/auction2023_hist_zscore.png", replace 
	   
	   
twoway (histogram z_score2 if selected==1, fcolor(blue%40)) ///
       (histogram z_score2 if selected==0, fcolor(red%40) ), ///
       legend(order(1 "Winners" 2 "Losers")) ///
       title("Standarized Score Distribution") xtitle("Score") /// 
	   note("2023 FA, log(score/ lowest winning score)")
graph export "$figures/auction2023_hist_zscore(2).png", replace 
   
	   
 