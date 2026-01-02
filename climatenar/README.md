# ClimateNAr RestRserve Container

Standalone container for the ClimateNAr REST API and smoke testing.
This image installs ClimateNAr from the local repo because the upstream zip
requires authentication.

## Build
Build from the ClimateNAr repo root so the Dockerfile can copy the package data:

```bash
docker build -f /workdir/ClimateNAr/climatenar/Dockerfile /workdir/ClimateNAr -t climatenar:dev
```

## Run (API)

```bash
docker run --rm -p 8008:8000 climatenar:dev
```

## API Reference

### Health Check

```
GET /v1/health
```

Returns API status and version.

**Response:**
```json
{"status": "ok", "version": "v1"}
```

---

### List Available Models/Periods

```
GET /v1/models
```

Returns all available climate models and time periods.

**Query Parameters:**
| Parameter | Description |
|-----------|-------------|
| `type` | Filter by type: `normal`, `annual`, `decadal`, `gcm`, `ensemble` |
| `scenario` | Filter by scenario (e.g., `ssp126`, `ssp245`, `ssp585`) |
| `model` | Filter by model name |
| `refresh` | Set to `true` to refresh the model cache |

**Response:**
```json
{
  "count": 509,
  "models": [
    {"id": "Normal_1961_1990.nrm", "type": "normal", "model": "historical", ...},
    ...
  ]
}
```

---

### Get Monthly Climate Data

```
POST /v1/monthly
```

Returns monthly climate variables (temperature, precipitation) for provided locations.

**Query Parameters:**
| Parameter | Default | Description |
|-----------|---------|-------------|
| `period` | `Normal_1961_1990.nrm` | Climate model/period ID (from `/v1/models`) |
| `format` | `json` | Response format: `json` or `csv` |

**Request Body:** CSV with required columns `ID1`, `ID2`, `lat`, `lon`, `elev`

```csv
ID1,ID2,lat,lon,elev
siteA,1,48.98,-115.02,1000
siteB,2,49.25,-115.10,900
```

**JSON Response:**
```json
{
  "period": "Normal_1961_1990.nrm",
  "units": {"tmin": "C", "tmax": "C", "precip": "mm"},
  "results": [
    {
      "id1": "siteA",
      "id2": "1",
      "lat": 48.98,
      "lon": -115.02,
      "elev_m": 1000,
      "tmin_c": [-11, -8.2, -5.1, -1.4, 2.5, 6.2, 8.1, 7.5, 3.4, -0.6, -4.9, -9.5],
      "tmax_c": [-2.6, 1.9, 6.1, 12.2, 17.2, 21.6, 26.2, 25.6, 19.4, 11.9, 2.9, -2.1],
      "precip_mm": [55, 38, 35, 36, 61, 66, 40, 43, 40, 32, 51, 55]
    }
  ]
}
```

**CSV Response** (`format=csv`):
```csv
ID1,ID2,lat,lon,elev,period,tmin_01_c,tmax_01_c,precip_01_mm,...,tmin_12_c,tmax_12_c,precip_12_mm
siteA,1,48.98,-115.02,1000,Normal_1961_1990.nrm,-11,-2.6,55,...,-9.5,-2.1,55
```

**Example:**
```bash
curl -X POST "http://localhost:8008/v1/monthly?period=Normal_1961_1990.nrm" \
  -H "Content-Type: text/csv" \
  --data-binary @locations.csv
```

---

### Error Responses

All errors return JSON with this structure:

```json
{"error": {"code": "error_code", "message": "Human-readable message", "details": []}}
```

| HTTP Status | Code | Description |
|-------------|------|-------------|
| 400 | `invalid_input` | Missing required CSV columns or invalid data |
| 404 | `unknown_period` | Requested period/model not found |
| 413 | `too_many_rows` | Input exceeds `MAX_ROWS` limit |
| 500 | `internal_error` | Server-side processing error |

---

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8000` | API listen port |
| `MAX_ROWS` | `10000` | Maximum rows per request |

### Performance Notes

**Request processing time:** The `/v1/monthly` endpoint typically takes **30-60 seconds** per request due to ClimateNAr's downscaling computations. Clients should use appropriate timeouts (e.g., `curl --max-time 180`).

---

## Smoke Test (Monthly Output)

```bash
docker run --rm climatenar:dev Rscript /srv/app/smoke_test.R
```

This writes a sample output CSV to `/srv/app/smoke_output.csv` inside the
container and prints the column names to stdout.

Monthly columns for tmin/tmax/precip are:
`Tmin01..Tmin12`, `Tmax01..Tmax12`, `PPT01..PPT12`.

Note: `ClimateNAr` performs a version validation HTTP call on each run. The
container needs outbound network access or the function will fail.

## Compose/Kubernetes Snippet

```yaml
services:
  climatenar:
    image: climatenar:dev
    ports:
      - "8008:8000"
    environment:
      PORT: 8000
      MAX_ROWS: 10000
```

## Notes
- Exposes the API on port 8000 inside the container.
- Uses the local `/workdir/ClimateNAr` package source at build time.
