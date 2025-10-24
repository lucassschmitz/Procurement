Correr la última celda del scrapper


# car_data README — Inputs & Outputs per Notebook

This folder builds a clean dataset of **car model characteristics** (specs, equipamiento, list price) from *Autocosmos* and merges it with **Convenio Marco** (CM) data for analysis.

## Run order (overview)
1. **1_preprocess.ipynb** → parses model strings into structured fields.  
2. **2_scrapper.ipynb** → discovers brand/model URLs, scrapes versions/specs/equipment, and produces a model–version dataset.  
3. **3_regression.ipynb** → links scraped data to CM (Maestra/Transacciones) and produces merge-ready outputs.

---

## 1) 1_preprocess.ipynb

**Purpose.** Parse the free‑text `modelo` into structured components and keep two parallel outputs:
- a base version (brand/model/tipo only), and
- an ID‑enriched version (with `numero licitacion` / `id producto` carried through).

### Inputs
"Maestra" with all the cars of each FA. 

### Outputs
- `csvs/unique_marca_modelo_by_tipo_producto.csv`  
  Unique combinations of **marca**, **modelo**, **tipo producto**.
- `csvs/unique_marca_modelo_by_tipo_producto_ids.csv`  
  Same as above **but includes IDs** (e.g., `numero licitacion`, `id producto`) for each record.
- `csvs/parsed_output_ids.csv`  
  original columns (excl. `modelo`) + parsed fields + ID columns (e.g., `numero licitacion`, `id producto`).

---

## 2) 2_scrapper.ipynb

**Purpose.** Build web targets from Autocosmos, match them to parsed models, then scrape **versions**, **specs**, **equipamiento**, and **list price**.

### Inputs
- `csvs/parsed_output.csv`  
  (from *1_preprocess*)
- `csvs/unique_marca_modelo_by_tipo_producto.csv`  
  List of brands used to seed discovery.
- [Intermediates if already run/iterated]  
  - `csvs/models_by_marcas.csv`  
  - `csvs/models_by_marcas_cleaned.csv`  
  - `csvs/parsed_output_with_urls.csv` / `csvs/parsed_output_with_urls_2.csv`  
  - `csvs/unique_model_urls.csv`  
  - `csvs/model_versions.csv`  
  - `csvs/matched_versions.csv`

### What it does (high‑level steps)
1. **Brand → model discovery** on Autocosmos; writes raw brand/model/URL list.
2. **Cleaning of model names** (remove brand duplications / boilerplate suffixes).
3. **Match parsed models ↔ Autocosmos model URLs** (exact/substring/fuzzy); write enriched parsed file with a **Version URL** pointer and a **unique list of model URLs** to crawl.
4. **Scrape model pages** to extract version names/links (`model_versions.csv`).
5. **Match parsed models ↔ specific version(s)** (`matched_versions.csv`).
6. **Scrape version pages** for **specs, equipamiento, list price** → `scraped_data.csv`.

### Outputs
- `csvs/models_by_marcas.csv`  
  Raw brand → [model, model_url] discovered in Autocosmos.
- `models_by_marcas_cleaned.csv` *(note: saved at repo root — consider moving to `csvs/` for consistency)*  
  Cleaned model names for matching. 
- `csvs/parsed_output_with_urls_2.csv`  
  `parsed_output.csv` + best **Version URL** candidate per row.
- `csvs/unique_model_urls.csv`  
  De‑duplicated list of **model detail URLs** to crawl.
- `csvs/model_versions.csv`  
  Extracted **versions per model** (name/URL).
- `csvs/matched_versions.csv`  
  Match between parsed models and specific **version URL(s)**.
- `csvs/scraped_data.csv`  
  **Final scrape**: wide table of specs/equipment/price per (brand, model, version).

---

## 3) 3_regression.ipynb

**Purpose.** Connect scraped Autocosmos data with CM **Maestra** and **Transacciones** to enable analysis and plotting.

### Inputs
- `csvs/scraped_data.csv`  
  (from *2_scrapper*)
- CM Maestra (raw, semicolon delimited):  
  - `../raw_data/ConvenioMarco/vehiculos_2023/MaestraProd_cm_2239-8-lr23.csv`  
  - `../raw_data/ConvenioMarco/vehiculos_2021/MaestraProd_cm_2239-5-lr21.csv`  
  - `../raw_data/ConvenioMarco/vehiculos_2017/MaestraProd_cm_2239-4-lr17.csv`
- Transactions (prebuilt upstream):  
  - `csvs/combined_transacciones_cm.csv`
  - (Sometimes also `csvs/transacciones_cm_2021.csv`, `csvs/transacciones_cm_2023.csv` in intermediate cells)

### What it does (high‑level steps)
1. **Standardizes Maestra** (encodings, column names, whitespace) and builds a grouped model table with a stable key.
2. **Assigns an `our_id`** to each scraped row by matching to the grouped model table.
3. **Merges scraped data with transactions** via `our_id` or fuzzy brand/model matches.
4. Produces **merge‑ready outputs** for downstream regressions/plots.

### Outputs
- `csvs/final_grouped_modelo.csv`  
  Grouped/standardized CM model table with stable keys.
- `csvs/scraped_data_id.csv`  
  `scraped_data.csv` augmented with **our_id**.
- `merged_transacciones_combined.csv`  
  Merge of 2021/2023 transactions with `scraped_data_id.csv` (outer file saved at repo root). 
- `final_matched_data.csv`  
  Fuzzy‑matched **final** table combining transactions and scraped specs/price.

---

## Conventions & tips
- **Paths:** Prefer saving all intermediates under `csvs/` for consistency (a couple of cells currently write to repo root).
- **Normalization:** Keep **lowercase, ASCII** column names when matching. Replace accented characters and normalize whitespace.
- **Robustness:** Add `timeout`, `retry` on HTTP 500s, and `on_bad_lines='skip'` where needed for CSVs with encoding issues.
- **Reproducibility:** When iterating, keep `_2` suffixes only temporarily. Once stable, consolidate filenames (e.g., overwrite `parsed_output_with_urls.csv`).

