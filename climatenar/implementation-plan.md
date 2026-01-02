# ClimateNAr RestRserve Implementation Plan

## Goal
Create a containerized RestRserve service that exposes:
- `/v1/models` for available ClimateNAr periods/models
- `/v1/monthly` for monthly precip, tmin, tmax from CSV location batches

Service will run under the `wepppy` docker stack.

## Assumptions and Constraints
- ClimateNAr is packaged as an installed R package with large data payloads.
- The `ClimateNAr` function requires at least two data rows in the input.
- Monthly variable names from ClimateNAr need a verified mapping.
- Container base must include GDAL/PROJ/GEOS for `terra`.

## Implementation Steps

1. **Vendor ClimateNAr into the build context**
   - Use `/workdir/ClimateNAr` as the Docker build context.
   - Copy the existing package layout directly into
     `/usr/local/lib/R/site-library/ClimateNAr` (no `R CMD INSTALL` needed).
   - Record the chosen method in a README near the Dockerfile.

2. **Create the RestRserve app**
   - Add `wepppy/services/climatenar/` with:
     - `app.R` (RestRserve entrypoint)
     - `handlers.R` (endpoint handlers)
     - `helpers.R` (CSV parsing, validation, model discovery, mapping)
   - Use `RestRserve::Application$new()` and register routes:
     - `GET /v1/health`
     - `GET /v1/models`
     - `POST /v1/monthly`

3. **Model discovery helper**
   - Use `system.file("data", package="ClimateNAr")` to locate data files.
   - Walk `historical/`, `GCMs/`, and `GCMs/Annual/` for `.rda` basenames.
   - Parse metadata with regex:
     - `Normal_YYYY_YYYY.nrm` -> type `normal`
     - `Year_YYYY.ann` -> type `annual`
     - `Decade_YYYY_YYYY.dcd` -> type `decadal`
     - `<model>_sspXXX_YYYY-YYYY.gcm` -> type `gcm`
     - `8GCMs_ensemble_sspXXX_YYYY-YYYY.gcm` -> type `ensemble`
   - Cache the list at startup; allow `?refresh=true` to rebuild.

4. **Monthly handler core**
   - Parse CSV into `data.table` or `readr::read_csv` with strict column
     validation (`ID1, ID2, lat, lon, elev`).
   - If only one row is provided, duplicate it, then drop the extra row from
     output.
   - Validate lat/lon ranges and numeric elevation.
   - Build `periodList` from request.
   - Determine `varList`:
     - Start with `varList="M"` and filter output columns to tmin/tmax/precip.
     - Add a mapping config (regex list) to normalize output names.
   - Call `ClimateNAr(inputFile=df, periodList=periodList, varList=varList,
     outDir=tempdir())`.
   - Detect whether `ClimateNAr` returns a data frame or writes to disk, and
     handle both cases.

5. **Variable mapping verification**
   - Verified monthly columns from `ClimateNAr` output:
     `Tmin01..Tmin12`, `Tmax01..Tmax12`, `PPT01..PPT12`.
   - Keep regex mapping in `helpers.R` aligned to these names.
   - Add an assertion to fail fast if expected columns are missing.

6. **Response formatting**
   - JSON: return arrays of 12 values per variable.
   - CSV: flatten to `tmin_01_c`..`tmin_12_c`, `tmax_01_c`..`tmax_12_c`,
     `precip_01_mm`..`precip_12_mm`.
   - Include `period` and the original ID columns.

7. **Error handling and limits**
   - Centralize errors with `tryCatch` and consistent JSON error payloads.
   - Add limits via env vars: `MAX_ROWS`, `REQUEST_TIMEOUT_S`.
   - Reject inputs larger than `MAX_ROWS` with a `413` response.

8. **Docker image**
   - Create `wepppy/docker/Dockerfile.climatenar` (or
     `wepppy/docker/climatenar/Dockerfile`) using `rocker/r-ver:4.4.2`.
   - Install system libs: `gdal-bin`, `libgdal-dev`, `libproj-dev`, `libgeos-dev`,
     `libudunits2-dev`.
   - Install R packages: `RestRserve`, `data.table`, `terra`, `readr`, `jsonlite`.
   - Install ClimateNAr and copy service code into `/srv/app`.
   - Expose port `8000` and run `Rscript /srv/app/app.R`.

9. **Docker compose integration**
   - Add a `climatenar` service to:
     - `docker/docker-compose.dev.yml`
     - `docker/docker-compose.prod.yml`
   - Include health check hitting `/v1/health`.
   - Configure env vars for limits and logging.

10. **Validation checklist**
    - `GET /v1/models` returns non-empty list.
    - `POST /v1/monthly` works with a 2-row CSV.
    - `POST /v1/monthly` works with a 1-row CSV (row duplication workaround).
    - CSV and JSON output formats are correct.
    - Monthly variable mapping is verified and stable.

## Open Questions to Resolve Early
- Confirm the exact monthly column names returned by ClimateNAr.
- Decide whether to install ClimateNAr from local repo or upstream zip.
- Choose API port and network exposure within the wepppy stack.
