# 02_extract_dhw_at_survey

## Purpose

This script extracts *Degree Heating Week (DHW)* values from NOAA Coral Reef Watch NetCDF files and appends them to each row in `df_exact` based on latitude, longitude, and date.

## Data source

- NOAA Coral Reef Watch (5km daily DHW product)
https://www.star.nesdis.noaa.gov/pub/socd/mecb/crw/data/5km/
- Files are downloaded per date and cached locally in `temp_nc/`

## Workflow overview

1. For each row in `df_exact`:
- Build the NOAA file URL from `DATETIME`
- Download the NetCDF file if not already cached
- Open and validate the dataset
- Extract DHW using nearest grid point
- If missing, search nearby grid cells for a valid value

2. Store results in a new column: `DHW`

## Reproducibility

- The script is fully reproducible from the raw dataset
- All rows are reprocessed on each run 
- This ensure consistency if:
  - The input dataset changes
  - NOAA updates historical DHW products
  
** Important: Cached Data Behavior**

- Downloaded NetCDF files are stored in `temp_nc/`
- Re-running the script will reuse cached files by default
- To force retrieval of updated NOAA data:
```
import shutil
shutil.rmtree("temp_nc", ignore_errors=True)
```

## Assumptions

- Internet connection is available for missing files
- NOAA file structure and variable names remain consistent

## Notes

- Processing is sequential
- The nearest DHW grid-cell value is extracted
- A search radius of 10 grid cells is used only when the nearest DHW grid-vell value is missing
- The function always returns the closest valid DHW value within the search window

# 03_extract_peak_dhw_within_6mo

## Purpose

This notebook computes the maximum Degree Heating Weeks (DHW) within a ±182-day window around recorded coral bleaching events. It also calculates the timing offset between bleaching events and peak thermal stress.

## Data source

- NOAA Coral Reef Watch (5km daily DHW product)
https://www.star.nesdis.noaa.gov/pub/socd/mecb/crw/data/5km/
- Files are downloaded dynamically and cached locally in `temp_nc/`

## Workflow overview

1. For each bleaching event, define a ±182-day time window
2. Download corresponding daily DHW NetCDF files
3. Extract DHW values at event coordinates
4. Handle missing values using a spatial search
5. Compute:
   - Maximum DHW: `MAX_ANNUAL_DHW`
   - Date of maximum DHW: `DATE_OF_MAX_DHW`
   - Time difference from bleaching date: `DAYS_FROM_MAX_DHW`
   
## Reproducibility

- The script is fully reproducible from the previously filtered and expanded dataset (i.e., dataset previously filtered for exact dates and expanded with DHW values for each report)
- Requires internet access to download NOAA data
- Results depend on NOAA dataset availability

## Scalability

- Entire workflow is scalable to any uppdated coral bleaching database provided the format is consistent with the current one
- Processing is row-by-row and can be slow for large datasets
- Caching alleviate this issue
- Each event is processed sequentially. Parallel processing was tested but not included in the final workflow due to unresolved NetCDF/HDF read errors (see `experimental_parallel_processing.ipynb`)

## Notes/Limitations

- Network failures may result in missing data
- Temporary files are stored in /temp_nc/