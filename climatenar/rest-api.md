# ClimateNAr RestRserve API Spec

## Overview
This service exposes a small REST API for ClimateNAr to return monthly climate
normals for a list of locations. It is designed for container deployment as a
docker service under `/workdir/wepppy/docker` and runs all computation locally
using the ClimateNAr package data (no public ClimateNA API calls).

## Base URL and Versioning
- Base path: `/v1`
- All endpoints are versioned under `/v1` to allow future extensions.

## Content Types
- Requests:
  - `text/csv` for location batches
- Responses:
  - `application/json` (default)
  - `text/csv` when `format=csv` is specified

## Authentication
None (internal service). If external exposure is needed later, place it behind
an API gateway with auth.

## Common Error Format
```json
{
  "error": {
    "code": "invalid_input",
    "message": "lat must be between -90 and 90",
    "details": {}
  }
}
```

## Endpoints

### GET /v1/health
Health check for container orchestration.

Response:
```json
{
  "status": "ok",
  "version": "v1"
}
```

### GET /v1/models
List available climate periods/models discovered from the installed ClimateNAr
data directory. This includes historical normals, annual and decadal records,
and future GCM periods.

Query parameters:
- `type`: `normal|annual|decadal|gcm|ensemble` (optional)
- `scenario`: `ssp126|ssp245|ssp370|ssp585` (optional)
- `model`: exact model name (optional, example: `MRI-ESM2-0`)

Response:
```json
{
  "count": 3,
  "models": [
    {
      "id": "Normal_1961_1990.nrm",
      "type": "normal",
      "model": "historical",
      "scenario": null,
      "label": "Normal 1961-1990"
    },
    {
      "id": "Year_2011.ann",
      "type": "annual",
      "model": "historical",
      "scenario": null,
      "label": "Year 2011"
    },
    {
      "id": "MRI-ESM2-0_ssp245_2041-2070.gcm",
      "type": "gcm",
      "model": "MRI-ESM2-0",
      "scenario": "ssp245",
      "label": "MRI-ESM2-0 ssp245 2041-2070"
    }
  ]
}
```

Notes:
- `id` values match ClimateNAr `periodList` identifiers (file basename without
  `.rda`).
- Period discovery is based on the local package data; no external API calls.

### POST /v1/monthly
Run ClimateNAr for a CSV list of locations and return monthly precipitation,
minimum temperature, and maximum temperature.

Request (raw CSV):
```
POST /v1/monthly?period=Normal_1961_1990.nrm&format=json
Content-Type: text/csv

ID1,ID2,lat,lon,elev
siteA,1,48.98,-115.02,1000
siteB,2,49.25,-115.10,900
```

Response (JSON):
```json
{
  "period": "Normal_1961_1990.nrm",
  "units": {
    "tmin": "C",
    "tmax": "C",
    "precip": "mm"
  },
  "results": [
    {
      "id1": "siteA",
      "id2": "1",
      "lat": 48.98,
      "lon": -115.02,
      "elev_m": 1000,
      "tmin_c": [ -7.2, -5.9, -1.7, 2.8, 7.1, 10.3, 12.1, 11.6, 8.0, 3.0, -2.5, -6.1 ],
      "tmax_c": [ 0.1, 2.3, 6.9, 12.8, 17.9, 21.4, 24.6, 24.1, 19.2, 12.3, 4.8, 0.9 ],
      "precip_mm": [ 82.1, 63.4, 58.2, 44.3, 55.1, 62.7, 44.9, 42.5, 48.6, 70.2, 86.0, 92.3 ]
    }
  ]
}
```

Response (CSV):
```
id1,id2,lat,lon,elev_m,period,tmin_01_c,...,tmin_12_c,tmax_01_c,...,tmax_12_c,precip_01_mm,...,precip_12_mm
siteA,1,48.98,-115.02,1000,Normal_1961_1990.nrm,-7.2,...,-6.1,0.1,...,0.9,82.1,...,92.3
```

Validation rules:
- `lat` in [-90, 90], `lon` in [-180, 180]
- `elev` must be numeric (meters)
- CSV must have at least 1 data row; the server will internally duplicate a row
  if needed to satisfy the ClimateNAr minimum row requirement.

Error codes:
- `400 invalid_input` for malformed CSV, missing columns, or invalid ranges
- `404 unknown_period` when `period` is not in `/v1/models`
- `413 too_many_rows` when input exceeds configured limits
- `500 internal_error` for unexpected failures

## Limits (Default)
- `MAX_ROWS`: 10000
- `REQUEST_TIMEOUT_S`: 300
These are configurable via environment variables.

## Variable Mapping Note
The ClimateNAr monthly variable names are mapped to canonical output fields:
- `tmin_c`: monthly minimum temperature
- `tmax_c`: monthly maximum temperature
- `precip_mm`: monthly precipitation

Verified ClimateNAr column names:
- `Tmin01`..`Tmin12`
- `Tmax01`..`Tmax12`
- `PPT01`..`PPT12`
