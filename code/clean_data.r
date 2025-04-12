library(dplyr)
library(readr)
library(lubridate)
library(stringr)
library(stringi)
library(readxl)
library(tidyr)
library(fuzzyjoin)
library(stringdist)
library(dplyr)

rm(list = ls())

setwd("C:/Users/lucas/OneDrive - Yale University/Documents/GitHub/2nd-year-paper/interm_data") 


########################
###### Functions ######

# to standarize the name of the columns 
rename_columns <- function(df) {
  df <- df %>%
    rename(`Fecha Envío OC` = `Fecha EnvÃ­o OC`, 
           `Región Unidad de Compra` = `RegiÃ³n Unidad de Compra`,
           `Institución` = `InstituciÃ³n`)
  return(df)
}

# Function to clean the 'Modelo' column
clean_modelo <- function(modelo, n_words = 3) { 
  modelo <- tolower(modelo) #convert to lowercase
  
  words_to_remove <- c("highline", "ltz", "xlt", "xls", "elite", "plus", "luxury", "comfort", 
                       "pick", "pick-up", "high", "z71", "diesel", "sport", "ltd", "limited", 
                       "-up", "premier", "advance", "new", "nueva", "nuevo")

  modelo <- str_replace_all(modelo, paste0("\\b(", paste(words_to_remove, collapse = "|"), ")\\b"), "")   # Remove the specified words
  modelo <- str_squish(modelo) # Trim extra spaces

  words <- str_split(modelo, "\\s+")[[1]]
  modelo <- paste(head(words, n_words), collapse = " ")
  #modelo <- str_extract(modelo, "^\\S+\\s*\\S*\\s*\\S*") # Select only the first 3 words

  return(modelo)
}

standardize_region <- function(x) {
  # work on a lower‑case, trimmed copy for pattern matching
  #clean <- str_to_lower(str_trim(x))
  clean <- str_to_lower(x)

  sapply(clean, function(z) {
    if (str_detect(z, "uble")) {
      "Nuble"
    } else if (str_detect(z, "val")) {
      "Valparaiso"
    } else if (str_detect(z, "los r")) {
      "Los Rios"
    } else if (str_detect(z, "arau")) {
      "Araucania"  
    } else if (str_detect(z, "mag")) {
      "Magallanes"  
    } else if (str_detect(z, "tara")) {
      "Tarapaca"
    } else if (str_detect(z, "ay")) {
      "Aysen"
     } else if (str_detect(z, "ggin")) {
      "Ohiggins"
    } else if (str_detect(z, "-")) {
      "Biobio"    
    } else {
      str_to_title(z)  # leave untouched but prettified
    }
  }, USE.NAMES = FALSE)
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

    df$`Región Unidad de Compra` <- standardize_region(df$`Región Unidad de Compra`)
    
    #some checks 
    unique(df$`Nombre Producto ONU`) #check there are no products we do not want 
    unique(df$`Moneda`) #all prices in CLP
    print(df %>%  group_by(`Nro Licitación Pública`) %>% summarize(count = n()))
    print( df %>%  count(`Nro Licitación Pública`, `Id Convenio Marco`))
    unique(df$`Región Unidad de Compra`) #check the regions are not repeated with different spellings 
    print(summary(df$'Precio Unitario')) # summarize 'Precio Unitario'
   

#### prepare data for storing  
    df$Precio_un <- df$`Monto Total OC` / df$`Cantidad` #the price per unit including taxes and potentially delivery costs 

    print(summary(df$Precio_un))

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

    df <- read_csv(file.path(trans_path, "cleaned_transactions_all_years.csv"))
    #df <- df %>% select(Producto, `Tipo de Producto`, Marca, Modelo, CodigoOC)
 
### Prepare the scraped data
  df_scraped <- read_csv( file.path(getwd(), "../car_data/csvs/scraped_data.csv"))
  df_scraped <- df_scraped %>%
                mutate(modelo = sapply(`model name`, clean_modelo, n_words =2 ))

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
  
  df <- df %>% mutate(Modelo = sapply(Modelo, clean_modelo, n_words = 2))
  df$merge_var <- tolower(paste(df$Marca, df$Modelo, sep = "_")) # important to use lower case letters. 


  df <- df %>% mutate(row_id = row_number()) # add row number to df

  merged_df <- stringdist_left_join(df, df_scraped, 
                                  by = "merge_var", 
                                  method = "jw",      # choose a method ("jw" is Jaro-Winkler) 
                                  max_dist = 0.2, 
                                  distance_col = "dist") %>%
                                  group_by(row_id) %>%
                                  slice_min(order_by = dist, n = 1, with_ties = FALSE) %>%
                                  ungroup() 

# Compute descriptives of the matching quality
summary_stats <- merged_df %>% 
  summarise(
    avg_distance = mean(dist, na.rm = TRUE),
    num_matched = sum(!is.na(marca)),      # assuming 'marca' from df_scraped is non-missing if a match was found
    num_unmatched = sum(is.na(marca)),
    share_matched = num_matched / n(),
    share_unmatched = num_unmatched / n()
  )

# Print summary statistics
print(summary_stats)

############ 
#############3 
########### 
############# 
############ 


merged_df %>%
  summarise(
    mean_precio = mean(Precio_un, na.rm = TRUE),
    median_precio = median(Precio_un, na.rm = TRUE),
    sd_precio = sd(Precio_un, na.rm = TRUE),
    min_precio = min(Precio_un, na.rm = TRUE),
    max_precio = max(Precio_un, na.rm = TRUE),
    count = n()
  )


  333 270 063

merged_df <- merged_df %>% 
  mutate(semester = year * 10L + if_else(month <= 6L, 1L, 2L)) # create semester variable

merged_df <- merged_df %>% 
  group_by(semester, `Región Unidad de Compra`) %>% 
  mutate(market = cur_group_id()) %>% 
  ungroup() # create market variable

 
merged_df <- merged_df %>%
  group_by(market) %>%
  mutate(N = n()) %>%
  ungroup() # market size 

shares_df <- merged_df %>% 
  group_by(market, IDProductoCM) %>% 
  summarise(
    count  = n(),                                   # sales of this product
    N      = first(N),                              # market size
    share  = count / N,                             # s_{jm}
    tipo   = first(`Tipo de Producto`)              # keep the product type
  ) %>% 
  ungroup()


## merged_df but with the market shares at the rigt. 
shares_df2 <- merged_df %>% 
  ## market size
  group_by(market) %>% 
  mutate(N = n()) %>% 
  ungroup() %>% 
  ## product‑level counts inside each market  → share
  group_by(market, IDProductoCM) %>% 
  mutate(
    count = n(),                 # sales of this product in this market
    share = count / N            # market share
  ) %>% 
  ungroup()

shares_df3 <- merged_df %>% # just like shares_df but keeping the other vars. 
  group_by(market, IDProductoCM) %>% 
  summarise(
    count  = n(),                 # sales of this product in this market
    N      = first(N),            # market size
    share  = count / N,           # market share
    across(everything(), first),  # keep one copy of every other column
    .groups = "drop"
  )


## run most basic logit 
logit_df <- shares_df %>% 
  filter(share > 0 & share < 1) %>% 
  mutate(
    logit_share = log(share / (1 - share)),
    tipo        = factor(tipo)          # <‑‑ here
  )
logit_model <- lm(logit_share ~ 0 + tipo, data = logit_df)
summary(logit_model)

 





% consider which variables to include in the logit 

########################################
# tab 
aux2 <- table(merged_df$semester, merged_df$`market`)
print(aux2)

# number of distinct values in column x
n_unique_x <- dplyr::n_distinct(merged_df$`Región Unidad de Compra`)

# columns of df 
print(names(merged_df)) # "Fecha Envío OC", "Región Unidad de Compra"

#print the values of x 
print(unique(merged_df$`Región Unidad de Compra`))