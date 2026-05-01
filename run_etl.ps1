param()
Set-Location "d:\GPP\Week_21\Metadata-Driven-ETL-Orchestration-Framework"

Write-Host "=== Step 1: Setting Docker context ===" -ForegroundColor Cyan
docker context use desktop-linux
$r = docker ps 2>&1
if ($r -match "pipe|cannot|failed|daemon") {
    Write-Host "Docker not ready yet, waiting 30s..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    docker ps 2>&1
}

Write-Host ""
Write-Host "=== Step 2: docker compose down (clean slate) ===" -ForegroundColor Cyan
docker compose down -v 2>&1

Write-Host ""
Write-Host "=== Step 3: docker compose up --build --detach ===" -ForegroundColor Cyan
docker compose up --build --detach
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: docker compose up failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Step 4: Waiting 90s for DB seed + orchestrator first run ===" -ForegroundColor Cyan
Start-Sleep -Seconds 90

Write-Host ""
Write-Host "=== Step 5: Orchestrator logs ===" -ForegroundColor Cyan
docker compose logs orchestrator

Write-Host ""
Write-Host "=== Step 6: DB Verification ===" -ForegroundColor Cyan
Write-Host "-- Audit Log --"
docker exec etl_db psql -U etl_user -d etl_db -c "SELECT pipeline_name, status, rows_read, rows_written FROM etl_audit_log ORDER BY run_id;"

Write-Host "-- Watermarks --"
docker exec etl_db psql -U etl_user -d etl_db -c "SELECT * FROM etl_watermarks;"

Write-Host "-- Row counts in destination tables --"
docker exec etl_db psql -U etl_user -d etl_db -c "SELECT 'dest_csv_customers' AS tbl, COUNT(*) AS cnt FROM dest_csv_customers UNION ALL SELECT 'dest_products', COUNT(*) FROM dest_products UNION ALL SELECT 'dest_api_events', COUNT(*) FROM dest_api_events;"

Write-Host "-- Cycle pipelines (expect 0 rows) --"
docker exec etl_db psql -U etl_user -d etl_db -c "SELECT pipeline_name, status FROM etl_audit_log WHERE pipeline_name IN ('cycle-A','cycle-B');"

Write-Host ""
Write-Host "=== ALL DONE ===" -ForegroundColor Green
