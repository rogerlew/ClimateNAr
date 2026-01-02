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

Health check:

```bash
curl -s http://localhost:8008/v1/health
```

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
