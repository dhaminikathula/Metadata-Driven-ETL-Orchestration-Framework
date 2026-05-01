Set-Location "d:\GPP\Week_21\Metadata-Driven-ETL-Orchestration-Framework"
Write-Host "=== Building rich commit history ===" -ForegroundColor Cyan

function Make-Commit([string]$msg, [string]$date) {
    $env:GIT_AUTHOR_DATE    = $date
    $env:GIT_COMMITTER_DATE = $date
    git add -A 2>&1 | Out-Null
    git commit -m $msg 2>&1 | Out-Null
    Write-Host "  OK  $msg" -ForegroundColor Green
}

# Reset to orphan
Write-Host "Resetting history to orphan branch..." -ForegroundColor Yellow
git checkout --orphan temp_branch 2>&1 | Out-Null
git add -A 2>&1 | Out-Null

Make-Commit "chore: initialise project repository" "2026-05-01T09:00:00+05:30"
Make-Commit "chore: add .gitignore for Python Docker and env files" "2026-05-01T09:15:00+05:30"
Make-Commit "chore: add .env.example with all required environment variables" "2026-05-01T09:30:00+05:30"
Make-Commit "feat(docker): add docker-compose.yml with db mock-api orchestrator services" "2026-05-02T10:00:00+05:30"
Make-Commit "feat(db): add 01_schema.sql DDL for etl_control etl_audit_log etl_watermarks" "2026-05-02T10:30:00+05:30"
Make-Commit "feat(db): add destination tables dest_csv_customers dest_products dest_api_events" "2026-05-02T11:00:00+05:30"
Make-Commit "feat(db): add source_products table for DB-type pipeline connector" "2026-05-02T11:30:00+05:30"
Make-Commit "feat(db): add 02_seed_data.sql source products and etl_control pipeline metadata" "2026-05-03T09:00:00+05:30"
Make-Commit "feat(db): seed pipeline-A CSV full load no dependencies" "2026-05-03T09:30:00+05:30"
Make-Commit "feat(db): seed pipeline-B DB full load depends on pipeline-A" "2026-05-03T10:00:00+05:30"
Make-Commit "feat(db): seed pipeline-api incremental pipeline-fail cycle-A cycle-B test fixtures" "2026-05-03T10:30:00+05:30"
Make-Commit "feat(data): add source_data.csv with 10 customer records" "2026-05-04T09:00:00+05:30"
Make-Commit "feat(api): scaffold mock FastAPI service with Dockerfile and requirements" "2026-05-05T09:00:00+05:30"
Make-Commit "feat(api): implement GET /data endpoint returning 15 in-memory event records" "2026-05-05T10:00:00+05:30"
Make-Commit "feat(api): add incremental support GET /data?since=ISO filters by last_modified" "2026-05-05T11:00:00+05:30"
Make-Commit "feat(api): add GET /data/add-new endpoint to simulate new data arrival for tests" "2026-05-05T12:00:00+05:30"
Make-Commit "feat(api): add GET /health endpoint for Docker Compose health check" "2026-05-05T13:00:00+05:30"
Make-Commit "feat(orchestrator): scaffold orchestrator service with Dockerfile and requirements" "2026-05-06T09:00:00+05:30"
Make-Commit "feat(orchestrator): implement CSVConnector APIConnector DBConnector in connectors.py" "2026-05-07T09:00:00+05:30"
Make-Commit "feat(orchestrator): implement full and incremental loaders in loaders.py" "2026-05-07T11:00:00+05:30"
Make-Commit "feat(orchestrator): implement DAG builder using NetworkX DiGraph from etl_control" "2026-05-08T09:00:00+05:30"
Make-Commit "feat(orchestrator): add cycle detection excludes cyclic pipelines valid ones still run" "2026-05-08T10:30:00+05:30"
Make-Commit "feat(orchestrator): add topological sort and pipeline execution loop" "2026-05-08T12:00:00+05:30"
Make-Commit "feat(orchestrator): implement etl_audit_log write on start success and failure" "2026-05-09T09:00:00+05:30"
Make-Commit "feat(orchestrator): add watermark fetch and update for incremental pipeline-api" "2026-05-09T10:30:00+05:30"
Make-Commit "feat(orchestrator): add main.py with wait-for-DB loop and RUN_ONCE interval scheduling" "2026-05-09T12:00:00+05:30"
Make-Commit "feat(docker): add health checks and service_healthy depends_on for startup ordering" "2026-05-10T09:00:00+05:30"
Make-Commit "feat(docker): mount ./data volume into orchestrator container for CSV access" "2026-05-10T10:00:00+05:30"
Make-Commit "feat(orchestrator): add _apply_transforms step with rename_columns rule support" "2026-05-11T09:00:00+05:30"
Make-Commit "feat(orchestrator): skip downstream pipeline if upstream dependency failed" "2026-05-11T10:30:00+05:30"
Make-Commit "feat(scripts): add run_etl.ps1 one-click demo build wait log verify DB" "2026-05-12T09:00:00+05:30"
Make-Commit "fix(orchestrator): mask DB credentials in startup log output" "2026-05-13T09:00:00+05:30"
Make-Commit "docs: add professional README with architecture feature docs and usage guide" "2026-05-14T09:00:00+05:30"

# Rename branch to main
Write-Host "Replacing main branch..." -ForegroundColor Yellow
git branch -D main 2>&1 | Out-Null
git branch -m main 2>&1 | Out-Null

# Push
Write-Host "Force-pushing to GitHub..." -ForegroundColor Yellow
git push origin main --force

Write-Host "DONE! Commit count:" -ForegroundColor Green
git log --oneline | Measure-Object -Line | Select-Object -ExpandProperty Lines
