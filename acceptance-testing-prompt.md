# ClimateNAr RestRserve Acceptance Testing Prompt

````
You are a fresh agent performing acceptance testing for the ClimateNAr RestRserve service.

Scope and constraints:
- Work only in `/workdir/ClimateNAr`. Do not create/modify files outside this repo.
- Do not change source or docs unless explicitly asked; this is a test-only pass.
- Network access is enabled and required (ClimateNAr does a version validation HTTP call).
- Use Docker for all tests.
- **Important:** The `/v1/monthly` endpoint takes 30-60 seconds to process due to ClimateNAr's downscaling computations. Use `--max-time 180` for curl requests to this endpoint.

Repo layout:
- Service code + Dockerfile: `/workdir/ClimateNAr/climatenar`
- Package docs: `/workdir/ClimateNAr/ClimateNAr_package_v3.1.0.md`

Acceptance test checklist (run in order):

1) Build image:
```bash
docker build -f /workdir/ClimateNAr/climatenar/Dockerfile /workdir/ClimateNAr -t climatenar:accept
```

2) Smoke test (monthly output columns):
```bash
docker run --rm climatenar:accept Rscript /srv/app/smoke_test.R
```
- Confirm output includes monthly columns `Tmin01..Tmin12`, `Tmax01..Tmax12`, `PPT01..PPT12`.
- Confirm it writes `/srv/app/smoke_output.csv` inside the container (the script logs this).

3) Run API container:
```bash
docker run --rm -p 8008:8000 climatenar:accept
```
Keep this running in a terminal.

4) Health check:
```bash
curl -s http://localhost:8008/v1/health
```
Expect `{"status":"ok","version":"v1"}`.

5) Models list:
```bash
curl -s http://localhost:8008/v1/models | head -c 500
```
- Confirm the response is JSON and includes `Normal_1961_1990.nrm`.

6) Monthly JSON output (valid CSV):
```bash
cat <<'CSV' > /tmp/locations.csv
ID1,ID2,lat,lon,elev
siteA,1,48.98,-115.02,1000
siteB,2,49.25,-115.10,900
CSV

curl -s --max-time 180 -X POST "http://localhost:8008/v1/monthly?period=Normal_1961_1990.nrm" \
  -H "Content-Type: text/csv" \
  --data-binary @/tmp/locations.csv | head -c 1000
```
- Confirm JSON contains `results` with two entries.
- Confirm each entry has `tmin_c`, `tmax_c`, `precip_mm` arrays of length 12.

7) Monthly CSV output:
```bash
curl -s --max-time 180 -X POST "http://localhost:8008/v1/monthly?period=Normal_1961_1990.nrm&format=csv" \
  -H "Content-Type: text/csv" \
  --data-binary @/tmp/locations.csv | head -n 3
```
- Confirm header includes `tmin_01_c..tmin_12_c`, `tmax_01_c..tmax_12_c`, `precip_01_mm..precip_12_mm`.

8) Single-row input behavior:
```bash
cat <<'CSV' > /tmp/locations_one.csv
ID1,ID2,lat,lon,elev
siteA,1,48.98,-115.02,1000
CSV

curl -s --max-time 180 -X POST "http://localhost:8008/v1/monthly?period=Normal_1961_1990.nrm" \
  -H "Content-Type: text/csv" \
  --data-binary @/tmp/locations_one.csv | head -c 500
```
- Confirm success and that output contains exactly one location result.

9) Error cases:
- Unknown period:
```bash
curl -s -i -X POST "http://localhost:8008/v1/monthly?period=Nope_1900" \
  -H "Content-Type: text/csv" \
  --data-binary @/tmp/locations.csv | head -n 5
```
Expect 404 + `unknown_period`.

- Invalid CSV (missing columns):
```bash
cat <<'CSV' > /tmp/bad.csv
lat,lon,elev
48.98,-115.02,1000
CSV

curl -s -i -X POST "http://localhost:8008/v1/monthly" \
  -H "Content-Type: text/csv" \
  --data-binary @/tmp/bad.csv | head -n 5
```
Expect 400 + `invalid_input`.

- Row limit:
```bash
docker run --rm -p 8008:8000 -e MAX_ROWS=1 climatenar:accept
```
Then retry the monthly request from step 6 (with `--max-time 180`); expect 413 + `too_many_rows`.

Report back:
- Summarize pass/fail for each step.
- Include any error messages or unexpected outputs.
- Do not change files unless asked.
````
