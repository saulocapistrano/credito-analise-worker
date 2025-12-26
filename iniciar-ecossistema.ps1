# Script de inicialização do ecossistema de crédito (PowerShell)
# Este script automatiza a inicialização dos serviços na ordem correta

$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando ecossistema de crédito..." -ForegroundColor Cyan
Write-Host ""

# Passo 1: Criar rede Docker
Write-Host "📡 Passo 1: Verificando/criando rede Docker..." -ForegroundColor Yellow
$networkExists = docker network ls | Select-String "search-credit-network"

if ($networkExists) {
    Write-Host "⚠️  Rede search-credit-network já existe" -ForegroundColor Yellow
} else {
    docker network create search-credit-network
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Rede Docker criada" -ForegroundColor Green
    } else {
        Write-Host "❌ Erro ao criar rede Docker" -ForegroundColor Red
        exit 1
    }
}

# Passo 2: Iniciar search-credit
Write-Host ""
Write-Host "🔧 Passo 2: Iniciando search-credit (API + PostgreSQL + Kafka)..." -ForegroundColor Yellow
Set-Location ..\search-credit

if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ docker-compose.yml não encontrado em search-credit" -ForegroundColor Red
    exit 1
}

docker-compose up -d
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ search-credit iniciado" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao iniciar search-credit" -ForegroundColor Red
    exit 1
}

Write-Host "⏳ Aguardando inicialização completa (30 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Validação básica do Kafka
Write-Host "🔍 Validando Kafka..." -ForegroundColor Yellow
$kafkaCheck = docker exec search-credit-kafka kafka-topics.sh --list --bootstrap-server localhost:9092 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Kafka está respondendo" -ForegroundColor Green
} else {
    Write-Host "⚠️  Kafka ainda não está pronto, aguardando mais 30 segundos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# Passo 3: Verificar conectividade Kafka
Write-Host ""
Write-Host "🔍 Passo 3: Verificando conectividade do Kafka na rede Docker..." -ForegroundColor Yellow
$connectivityCheck = docker run --rm --network search-credit-network `
    confluentinc/cp-kafka:latest `
    kafka-broker-api-versions --bootstrap-server search-credit-kafka:9092 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Kafka acessível via rede Docker" -ForegroundColor Green
} else {
    Write-Host "⚠️  Kafka pode não estar totalmente pronto ainda" -ForegroundColor Yellow
}

# Passo 4: Iniciar credito-analise-worker
Write-Host ""
Write-Host "⚙️  Passo 4: Iniciando credito-analise-worker..." -ForegroundColor Yellow
Set-Location ..\credito-analise-worker

if (-not (Test-Path "docker-compose.yml")) {
    Write-Host "❌ docker-compose.yml não encontrado em credito-analise-worker" -ForegroundColor Red
    exit 1
}

docker-compose up -d worker
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ credito-analise-worker iniciado" -ForegroundColor Green
} else {
    Write-Host "❌ Erro ao iniciar credito-analise-worker" -ForegroundColor Red
    exit 1
}

Write-Host "⏳ Aguardando inicialização do worker (15 segundos)..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Validação do consumer
Write-Host "🔍 Validando consumer group..." -ForegroundColor Yellow
$consumerGroups = docker exec search-credit-kafka `
    kafka-consumer-groups.sh `
    --bootstrap-server localhost:9092 `
    --list 2>&1

if ($consumerGroups -match "analise-group") {
    Write-Host "✅ Consumer group 'analise-group' registrado" -ForegroundColor Green
} else {
    Write-Host "⚠️  Consumer group ainda não registrado (pode levar alguns segundos)" -ForegroundColor Yellow
}

# Passo 5: Iniciar search-credit-frontend (se existir)
Write-Host ""
Write-Host "🎨 Passo 5: Verificando search-credit-frontend..." -ForegroundColor Yellow
Set-Location ..

if (Test-Path "search-credit-frontend") {
    Set-Location search-credit-frontend
    
    if (Test-Path "docker-compose.yml") {
        Write-Host "Iniciando frontend..." -ForegroundColor Yellow
        docker-compose up -d
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ search-credit-frontend iniciado" -ForegroundColor Green
        } else {
            Write-Host "❌ Erro ao iniciar frontend" -ForegroundColor Red
        }
        Write-Host "⏳ Aguardando inicialização do frontend (20 segundos)..." -ForegroundColor Yellow
        Start-Sleep -Seconds 20
    } else {
        Write-Host "⚠️  docker-compose.yml não encontrado no frontend" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Diretório search-credit-frontend não encontrado (opcional)" -ForegroundColor Yellow
}

# Resumo final
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "✅ Inicialização concluída!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Status dos serviços:" -ForegroundColor Yellow
Write-Host ""

docker ps --filter "name=search-credit" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=credito-analise-worker" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

$frontendContainers = docker ps --filter "name=search-credit-frontend" --format "{{.Names}}"
if ($frontendContainers) {
    docker ps --filter "name=search-credit-frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

Write-Host ""
Write-Host "🔍 Para ver logs:" -ForegroundColor Yellow
Write-Host "  - search-credit: cd ..\search-credit; docker-compose logs -f"
Write-Host "  - worker: cd ..\credito-analise-worker; docker-compose logs -f worker"
if (Test-Path "..\search-credit-frontend") {
    Write-Host "  - frontend: cd ..\search-credit-frontend; docker-compose logs -f"
}
Write-Host ""
Write-Host "📖 Para mais detalhes, consulte: GUIA_INICIALIZACAO.md" -ForegroundColor Cyan
Write-Host ""

