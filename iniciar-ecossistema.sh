#!/bin/bash

# Script de inicialização do ecossistema de crédito
# Este script automatiza a inicialização dos serviços na ordem correta

set -e  # Parar em caso de erro

echo "🚀 Iniciando ecossistema de crédito..."
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para verificar se um comando foi bem-sucedido
check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

# Passo 1: Criar rede Docker
echo "📡 Passo 1: Verificando/criando rede Docker..."
if docker network ls | grep -q "search-credit-network"; then
    echo -e "${YELLOW}⚠️  Rede search-credit-network já existe${NC}"
else
    docker network create search-credit-network
    check_command "Rede Docker criada"
fi

# Passo 2: Iniciar search-credit
echo ""
echo "🔧 Passo 2: Iniciando search-credit (API + PostgreSQL + Kafka)..."
cd ../search-credit

if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml não encontrado em search-credit${NC}"
    exit 1
fi

docker-compose up -d
check_command "search-credit iniciado"

echo "⏳ Aguardando inicialização completa (30 segundos)..."
sleep 30

# Validação básica do Kafka
echo "🔍 Validando Kafka..."
if docker exec search-credit-kafka kafka-topics.sh --list --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    check_command "Kafka está respondendo"
else
    echo -e "${YELLOW}⚠️  Kafka ainda não está pronto, aguardando mais 30 segundos...${NC}"
    sleep 30
fi

# Passo 3: Verificar conectividade Kafka
echo ""
echo "🔍 Passo 3: Verificando conectividade do Kafka na rede Docker..."
if docker run --rm --network search-credit-network \
    confluentinc/cp-kafka:latest \
    kafka-broker-api-versions --bootstrap-server search-credit-kafka:9092 > /dev/null 2>&1; then
    check_command "Kafka acessível via rede Docker"
else
    echo -e "${YELLOW}⚠️  Kafka pode não estar totalmente pronto ainda${NC}"
fi

# Passo 4: Iniciar credito-analise-worker
echo ""
echo "⚙️  Passo 4: Iniciando credito-analise-worker..."
cd ../credito-analise-worker

if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ docker-compose.yml não encontrado em credito-analise-worker${NC}"
    exit 1
fi

docker-compose up -d worker
check_command "credito-analise-worker iniciado"

echo "⏳ Aguardando inicialização do worker (15 segundos)..."
sleep 15

# Validação do consumer
echo "🔍 Validando consumer group..."
if docker exec search-credit-kafka \
    kafka-consumer-groups.sh \
    --bootstrap-server localhost:9092 \
    --list 2>/dev/null | grep -q "analise-group"; then
    check_command "Consumer group 'analise-group' registrado"
else
    echo -e "${YELLOW}⚠️  Consumer group ainda não registrado (pode levar alguns segundos)${NC}"
fi

# Passo 5: Iniciar search-credit-frontend (se existir)
echo ""
echo "🎨 Passo 5: Verificando search-credit-frontend..."
cd ..

if [ -d "search-credit-frontend" ]; then
    cd search-credit-frontend
    
    if [ -f "docker-compose.yml" ]; then
        echo "Iniciando frontend..."
        docker-compose up -d
        check_command "search-credit-frontend iniciado"
        echo "⏳ Aguardando inicialização do frontend (20 segundos)..."
        sleep 20
    else
        echo -e "${YELLOW}⚠️  docker-compose.yml não encontrado no frontend${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Diretório search-credit-frontend não encontrado (opcional)${NC}"
fi

# Resumo final
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Inicialização concluída!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Status dos serviços:"
echo ""
docker ps --filter "name=search-credit" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=credito-analise-worker" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
if docker ps --filter "name=search-credit-frontend" --format "{{.Names}}" | grep -q .; then
    docker ps --filter "name=search-credit-frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
fi
echo ""
echo "🔍 Para ver logs:"
echo "  - search-credit: cd ../search-credit && docker-compose logs -f"
echo "  - worker: cd ../credito-analise-worker && docker-compose logs -f worker"
if [ -d "../search-credit-frontend" ]; then
    echo "  - frontend: cd ../search-credit-frontend && docker-compose logs -f"
fi
echo ""
echo "📖 Para mais detalhes, consulte: GUIA_INICIALIZACAO.md"
echo ""

