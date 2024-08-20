cls
set more off
set scheme s1color

else if c(username) == "lucas" {
	global root = "C:\Users\lucas\OneDrive - Yale University\2nd year paper\Procurement"
	capture confirm file $root
}
 
global raw ${root}\raw_data
global data ${root}\data

import delimited "${data}\lic_2022-1.csv", clear varnames(1) bindquote(nobind) 

* still the uploading is far from ideal. Should improve this part. 

drop if missing(link)
drop if substr(link, 1,3) != "htt" 
 
destring montoestimado 
by codigo: gen monto_adjudicado = 



toint
 * Tabulate some key categorical variables
tabulate procedenciaoc
tabulate estadooc
tabulate monedaoc

* Examine the distribution of the 'MontoTotalOC' variable
destring montototaloc, replace force

histogram montototaloc if montototaloc < 500000, percent normal


label define of_sel 1 "Adjudicada" 0 "No adjudicada"  
label values ofertaseleccion of_sel


label define race_grp 1 "White" 2 "Black or African American" 3 "American Indian or Alaska native" 4 "Asian" 5 "Native Hawaiian" 6 "Guamanian or Chamorro" 7 "Samoan" 8 "Other Pacific Islander" 9 "Other"
label values REF_RACE race_grp




codigo          link	codigoexterno   nombre          
descripcion     tipodeadquisi~n 
codigoestado    estado	        
codigoorganismo nombreorganismo sector	rutunidad       
codigounidad    strL    %9s                   CodigoUnidad
nombreunidad    strL    %9s                   NombreUnidad
direccionunidad strL    %9s                   DireccionUnidad
comunaunidad    strL    %9s                   ComunaUnidad
regionunidad    strL    %9s                   RegionUnidad
informada       strL    %9s                   Informada
codigotipo      strL    %9s                   CodigoTipo
tipo            strL    %9s                   Tipo
tipoconvocato~a strL    %9s                   TipoConvocatoria
codigomoneda    strL    %9s                   CodigoMoneda
monedaadquisi~n strL    %9s                   Moneda Adquisicion
etapas          strL    %9s                   Etapas
estadoetapas    strL    %9s                   EstadoEtapas
tomarazon       strL    %9s                   TomaRazon
estadopublici~s strL    %9s                   EstadoPublicidadOfertas
justificacion~d strL    %9s                   JustificacionPublicidad
estadocs        strL    %9s                   EstadoCS
contrato        strL    %9s                   Contrato
obras           strL    %9s                   Obras
cantidadrecla~s strL    %9s                   CantidadReclamos
fechacreacion   strL    %9s                   FechaCreacion
fechacierre     strL    %9s                   FechaCierre
fechainicio     strL    %9s                   FechaInicio
fechafinal      strL    %9s                   FechaFinal
fechapubrespu~s strL    %9s                   FechaPubRespuestas
fechaactoa~nica strL    %9s                   FechaActoAperturaTecnica
fechaactoa~mica strL    %9s                   FechaActoAperturaEconomica
fechapublicac~n strL    %9s                   FechaPublicacion
fechaadjudica~n strL    %9s                   FechaAdjudicacion
fechaestimada~n strL    %9s                   FechaEstimadaAdjudicacion
fechasoportef~o strL    %9s                   FechaSoporteFisico
fechatiempoev~n strL    %9s                   FechaTiempoEvaluacion
unidadtiempoe~n strL    %9s                   UnidadTiempoEvaluacion
fechaestimada~a strL    %9s                   FechaEstimadaFirma
fechasusuario   str75   %75s                  FechasUsuario
fechavisitate~o strL    %9s                   FechaVisitaTerreno
direccionvisita strL    %9s                   DireccionVisita
fechaentregaa~s str73   %73s                  FechaEntregaAntecedentes
direccionentr~a strL    %9s                   DireccionEntrega
estimacion      strL    %9s                   Estimacion
fuentefinanci~o str65   %65s                  FuenteFinanciamiento
visibilidadmo~o str52   %52s                  VisibilidadMonto
montoestimado   str52   %52s                  MontoEstimado
tiempo          strL    %9s                   Tiempo
unidadtiempo    strL    %9s                   UnidadTiempo
modalidad       strL    %9s                   Modalidad
tipopago        strL    %9s                   TipoPago
prohibicionco~n strL    %9s                   ProhibicionContratacion
subcontratacion strL    %9s                   SubContratacion
unidadtiempod~o strL    %9s                   UnidadTiempoDuracionContrato
tiempoduracio~o strL    %9s                   TiempoDuracionContrato
tipoduracionc~o strL    %9s                   TipoDuracionContrato
justificacion~o strL    %9s                   JustificacionMontoEstimado
observacionco~o strL    %9s                   ObservacionContrato
extensionplazo  strL    %9s                   ExtensionPlazo
esbasetipo      strL    %9s                   EsBaseTipo
unidadtiempoc~n strL    %9s                   UnidadTiempoContratoLicitacion
valortiempore~n strL    %9s                   ValorTiempoRenovacion
periodotiempo~n strL    %9s                   PeriodoTiempoRenovacion
esrenovable     strL    %9s                   EsRenovable
tipoaprobacion  strL    %9s                   TipoAprobacion
numeroaprobac~n strL    %9s                   NumeroAprobacion
fechaaprobacion strL    %9s                   FechaAprobacion
numerooferentes strL    %9s                   NumeroOferentes
correlativo     strL    %9s                   Correlativo
codigoestadol~n strL    %9s                   CodigoEstadoLicitacion
codigoitem      strL    %9s                   Codigoitem
codigoproduct~u strL    %9s                   CodigoProductoONU
rubro1          strL    %9s                   Rubro1
rubro2          strL    %9s                   Rubro2
rubro3          strL    %9s                   Rubro3
nombreproduct~o strL    %9s                   Nombre producto genrico
nombrelineaad~n strL    %9s                   Nombre linea Adquisicion
descripcionli~n strL    %9s                   Descripcion linea Adquisicion
unidadmedida    strL    %9s                   UnidadMedida
cantidad        strL    %9s                   Cantidad
codigoproveedor strL    %9s                   CodigoProveedor
codigosucursa~r strL    %9s                   CodigoSucursalProveedor
rutproveedor    strL    %9s                   RutProveedor
nombreproveedor strL    %9s                   NombreProveedor
razonsocialpr~r strL    %9s                   RazonSocialProveedor
descripcionpr~r strL    %9s                   DescripcionProveedor
montoestimado~o strL    %9s                   Monto Estimado Adjudicado
nombredelaofe~a strL    %9s                   Nombre de la Oferta
estadooferta    strL    %9s                   Estado Oferta
cantidadofert~a strL    %9s                   Cantidad Ofertada
monedadelaofe~a strL    %9s                   Moneda de la Oferta
montounitario~a strL    %9s                   MontoUnitarioOferta
valortotalofe~o strL    %9s                   Valor Total Ofertado
cantidadadjud~a strL    %9s                   CantidadAdjudicada
montolineaadj~a strL    %9s                   MontoLineaAdjudica
fechaenvioofe~a strL    %9s                   FechaEnvioOferta
ofertaselecci~a strL    %9s                   Oferta seleccionada
