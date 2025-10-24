
cd .. 
global data "raw_data\ConvenioMarco/transacciones"
global data_int "interm_data/transac"
global data_m "interm_data\transac\monthly_trans"
global figures "C:\Users\lucas\CH_Research Dropbox\Lucas Schmitz\Apps\Overleaf\Second year paper\figures\price_dispersion"
*log using "transacciones_import.log", text replace

**# Bookmark #1 use the data 

use  "$data_int/transacciones_all_cleaned.dta", clear

tab moneda
tab nombreproductoonu

drop nombreoc moneda nombreproductoonu direccionunidadcompra comunaunidadcompra unidaddecompra razonsocialcomprador institucion comunadelproveedor observaciones regiondelproveedor orgcode_comprador entcode_comprador orgcode_proveedor entcode_proveedor
////
tab nrolicitacionpublica
keep if nrolicitacionpublica == "2239-5-lr21"
drop nrolicitacionpublica idconveniomarco estadooc provienedegrancompra idgrancompra

tab tipodeproducto

tab nombreempresa
br if (rutproveedor == "79.649.140-k" & tipodeproducto == "suv")

br if (rutproveedor == "81.318.700-0" & tipodeproducto == "suv" )
br if (rutproveedor == "79.853.470-k" & tipodeproducto == "suv")
tab marca if (rutproveedor == "79.853.470-k" & tipodeproducto == "suv")

br if (rutproveedor == "96.981.470-6" & tipodeproducto == "suv")



br








/////////


drop conveniomarco idconveniomarco estadooc especificaciondelcomprador nombreoc nombreproducto producto moneda direccionunidadcompra razonsocialcomprador comunadelproveedor observaciones totalineaneto  descuentoglobaloc subtotaloc impuestos montototalocneto montototaloc cargosadicionalesoc

tab regionu	
tab  tipodeproducto

// data cleaning 
	replace preciounitario = preciounitario / 1e6
