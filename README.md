# 2nd year paper
# Here we will be uploading all the files used to analyze the procurement data
---

Extract - Transform

* \ET
    * \extract_files                  
        * extract_CM.ipynb          
        * extract_L_OC.ipynb    
    * \transform_files
        * merge_by_year_L_OC.ipynb
        * transform_CM_transactions.ipynb

# Licitaciones & Ordenes de Compra

* Run ```'extract_L_OC_.ipynb'``` to get monthly data from 'Licitaciones' and 'Ordenes de Compra'. Each dataset will be stored in ```\raw_data\Licitaciones\{year}\lic_{year}-{month}.csv``` and ```\raw_data\OrdenesCompra\{year}\{year}-{month}.csv``` respectively. Make sure to have existing ```\raw_data\Licitaciones``` and ```\raw_data\OrdenesCompra``` directories to avoid errors.

# Convenio Marco

* Run ```'extract_CM.ipynb'``` to get from 'Convenio Marco Vehículos 2023' data and monthly data from 'Transacciones Convenio Marco'. Each dataset will be stored in ```raw_data\ConvenioMarco\vehiculos_2023\MaestraProd_cm_2239-8-lr23.csv``` and ```\raw_data\ConvenioMarco\Transacciones\{year}\{year}-{month}.csv``` respectively. Make sure to have existing ```raw_data\ConvenioMarco\vehiculos_2023``` and ```\raw_data\ConvenioMarco\Transacciones\``` directories to avoid errors.

# Yearly datasets from Licitaciones & Ordenes de Compra

* Run ```'merge_by_year_L_OC.ipynb'``` to get monthly merged Licitaciones and Ordenes de Compra data by year. Each dataset will be stored in```interm_data\yearly_data\Licitaciones\lic-{year}.csv``` and ```interm_data\yearly_data\OrdenesCompra\oc-{year}.csv``` respectively. Make sure to have existing ```interm_data\yearly_data\Licitaciones``` and ```interm_data\yearly_data\OrdenesCompra``` directories to avoid errors.

# Transactions linked to Convenio Marco Vehículos 2021 and Convenio Marco Vehículos 2023.

* Run ```'transform_CM_transactions.ipynb'``` to get all the transactions linked to Convenio Marco Vehículos 2021 and Convenio Marco Vehículos2023. Each dataset will be stored in```interm_data\yearly_data\Transacciones\transacciones_cm_{year}.csv```. Make sure to have the existing ```interm_data\yearly_data\Transacciones```directory to avoid errors.

