library(dplyr)
library(readr)
library(lubridate)
library(stringr)
library(readxl)
library(tidyr)
library(fuzzyjoin)

setwd("C:/Users/lucas/OneDrive - Yale University/Documents/GitHub/2nd-year-paper/interm_data") 

# Functions 

# to standarize the name of the columns 
rename_columns <- function(df) {
  df <- df %>%
    rename(`Fecha Envío OC` = `Fecha EnvÃ­o OC`, 
           `Región Unidad de Compra` = `RegiÃ³n Unidad de Compra`,
           `Institución` = `InstituciÃ³n`)
  return(df)
}

# Function to clean the 'Modelo' column
clean_modelo <- function(modelo) {
  modelo <- tolower(modelo) #convert to lowercase
  
  words_to_remove <- c("highline", "ltz", "xlt", "xls", "elite", "plus", "luxury", "comfort", 
                       "pick", "pick-up", "high", "z71", "diesel", "sport", "ltd", "limited", 
                       "-up", "premier", "advance", "new", "nueva", "nuevo")

  modelo <- str_replace_all(modelo, paste0("\\b(", paste(words_to_remove, collapse = "|"), ")\\b"), "")   # Remove the specified words
  modelo <- str_squish(modelo) # Trim extra spaces
  modelo <- str_extract(modelo, "^\\S+\\s*\\S*\\s*\\S*") # Select only the first 3 words

  return(modelo)
}




### Join the transactions 
    trans_path <- file.path(getwd(),  "transac") 
    df_17 <- read_csv(file.path(trans_path, "transacciones_cm_2017.csv"))
    df_21 <- read_csv(file.path(trans_path, "transacciones_cm_2021.csv"))  
    df_23 <- read_csv(file.path(trans_path, "transacciones_cm_2023.csv"))
    
    df_21 <- rename_columns(df_21)
    df_23 <- rename_columns(df_23) 

    df <- bind_rows(df_17, df_21, df_23)
    #df_auctions <- read_excel(file.path(getwd(), "CM_auctions", "auction21.xlsx"))


##### clean the data 
    #drop certain values of 'Convenio Marco'
    unique(df$`Convenio Marco`)
    df <- df %>%
    filter(!`Convenio Marco` %in% c( "Compra de Vehículos Pesados y Maquinarias", 
    "Arriendo de Vehiculos a Largo Plazo"))

    #keep certain values of 'Tipo de Producto'
    aux <- df %>%
    group_by(`Tipo de Producto`) %>%
    summarize(avg_precio_unitario = mean(`Precio Unitario`, na.rm = TRUE), 
    count = n())
    print(aux) #avg. price per product

    #standarize 'Tipo de Producto'
    df <- df %>% mutate(`Tipo de Producto` = recode(`Tipo de Producto`, "SEDÃ\u0081N" = "SEDÁN",
                                        "HATCHBACK" = "SEDÁN", # hatchback are only 41 and look similar to SEDAN
                                        "FURGÃ\u0093N" = "FURGÓN"))

    df <- df %>% filter(`Tipo de Producto` %in% c("CAMIONETA", "SUV", "SEDÁN", "FURGÓN", "HATCHBACK"))


    #some checks 
    unique(df$`Nombre Producto ONU`) #check there are no products we do not want 
    unique(df$`Moneda`) #all prices in CLP
    print(df %>%  group_by(`Nro Licitación Pública`) %>% summarize(count = n()))
    print( df %>%  count(`Nro Licitación Pública`, `Id Convenio Marco`))


#### prepare data for storing  
    df$Precio_un <- df$`Monto Total OC` / df$`Cantidad` #the price per unit including taxes and potentially delivery costs 

    df <- df %>%mutate(Fecha_Envio_OC = ymd(`Fecha Envío OC`), year = year(Fecha_Envio_OC),  
            month = month(Fecha_Envio_OC))


    df <- df %>% select(`Rut Proveedor`, `Nombre Empresa`, `Nro Licitación Pública`, `CodigoOC`, `Proviene de Gran Compra`, `IDProductoCM`, 
        `Producto`, `Tipo de Producto`, `Marca`, `Modelo`, `Cantidad`, `Rut Unidad de Compra`, `Unidad de Compra`,  `Fecha Envío OC`,
        `Región Unidad de Compra`, `Institución`,`Sector`, `year`, `month`,`Precio_un`) 

    missing_counts <- colSums(is.na(df))
    aux <- missing_counts[missing_counts > 2]
    if (length(aux) > 0) {  print(aux)} else {  print("No columns have more than 2 missing values.")}

    #one obs had missing brand and was toyota
    df <- df %>%
        mutate(Marca = ifelse(is.na(Marca), "TOYOTA", Marca)) 

    write_csv(df, file.path(trans_path, "cleaned_transactions_all_years.csv"))


 
### Prepare the scraped data
  df_scraped <- read_csv( file.path(getwd(), "../car_data/csvs/scraped_data.csv"))

  df_scraped <- df_scraped %>%
                mutate(modelo = sapply(`model name`, clean_modelo))

  df_scraped <- df_scraped %>%
  mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), ~ na_if(., "N/D"))) #replace N/D with NA
  #df_scraped <- df_scraped %>% mutate(across(everything(), ~ na_if(., "N/D")))

  df_scraped <- df_scraped %>%
    select(where(~ mean(is.na(.)) <= .1)) # droop columns with many missings 

  # reduce the number of models 
  most_frequent <- function(x) {
    x <- na.omit(x)  # Remove NA values
    if (length(x) == 0) return(NA)  # Handle empty cases
    return(names(sort(table(x), decreasing = TRUE))[1])  # Get most frequent value
  }
  df_scraped <- df_scraped %>%
    group_by(modelo) %>%
    summarise(across(everything(), most_frequent), .groups = "drop")

  df_scraped$merge_var <- paste(df_scraped$marca, df_scraped$modelo, sep = "_")

## merge  
  
  df <- df %>%
      mutate(Modelo = sapply(Modelo, clean_modelo))
  df$merge_var <- paste(df$Marca, df$Modelo, sep = "_")

 
