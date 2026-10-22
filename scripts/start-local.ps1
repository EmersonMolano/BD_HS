param(
    [switch]$SkipMigrations
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $projectRoot '.env'
$composeFile = Join-Path $projectRoot 'docker-compose.yml'

if (-not (Test-Path $envFile)) {
    throw "Falta BD_HS/.env. Copia BD_HS/.env.example a BD_HS/.env y configura sus valores locales."
}

$composeArgs = @(
    '--env-file', $envFile,
    '-p', 'hidro_smart',
    '-f', $composeFile
)

Write-Host 'Levantando PostgreSQL y creando roles técnicos...'
docker compose @composeArgs up -d postgres db-bootstrap

if (-not $SkipMigrations) {
    Write-Host 'Validando y aplicando migraciones Liquibase...'
    docker compose @composeArgs --profile tooling run --rm --build liquibase validate
    docker compose @composeArgs --profile tooling run --rm --build liquibase update
}

Write-Host 'Base local lista en localhost:5433.'
