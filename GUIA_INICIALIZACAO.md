# 🚀 Guia de Inicialização do Ambiente Docker

Este guia descreve o processo completo de inicialização do ecossistema de crédito, garantindo que todos os serviços sejam iniciados na ordem correta e com suas dependências satisfeitas.

## 📋 Visão Geral do Ecossistema

O ecossistema é composto por três serviços principais:

1. **search-credit** - API principal com PostgreSQL e Kafka
2. **credito-analise-worker** - Worker que consome mensagens do Kafka
3. **search-credit-frontend** - Interface frontend que consome a API

## 🔗 Dependências entre Serviços

```
search-credit (PostgreSQL + Kafka)
    │
    ├───> credito-analise-worker (consome Kafka)
    │
    └───> search-credit-frontend (consome API REST)
```

### Detalhamento das Dependências

- **credito-analise-worker** depende de:
  - Kafka do `search-credit` estar rodando
  - Rede Docker `search-credit-network` existir

- **search-credit-frontend** depende de:
  - API do `search-credit` estar rodando e acessível
  - Porta da API estar disponível

- **search-credit** é o serviço base que fornece:
  - API REST
  - Banco de dados PostgreSQL
  - Kafka para mensageria

## ✅ Checklist Pré-Inicialização

Antes de iniciar os serviços, verifique:

- [ ] Docker e Docker Compose instalados e funcionando
- [ ] Portas disponíveis:
  - [ ] 8080 (API search-credit)
  - [ ] 8081 (Worker)
  - [ ] 3000 ou 5173 (Frontend - verificar no projeto)
  - [ ] 5432 (PostgreSQL)
  - [ ] 9092 (Kafka interno)
- [ ] Espaço em disco suficiente
- [ ] Memória RAM disponível (mínimo 4GB recomendado)

## 📝 Passo a Passo de Inicialização

### Passo 1: Criar a Rede Docker Compartilhada

**Por que é necessário:** Todos os serviços precisam estar na mesma rede Docker para se comunicarem via DNS interno.

```bash
# Verificar se a rede já existe
docker network ls | grep search-credit-network

# Se não existir, criar a rede
docker network create search-credit-network
```

**Validação:**
```bash
docker network inspect search-credit-network
```

**Resultado esperado:** Rede criada com driver `bridge` e sem containers conectados ainda.

---

### Passo 2: Iniciar o Serviço search-credit

**Por que primeiro:** Este serviço fornece:
- PostgreSQL (banco de dados)
- Kafka (mensageria)
- API REST (endpoint principal)

Os outros serviços dependem desses componentes.

**Comandos:**

```bash
# Navegar para o diretório do search-credit
cd ../search-credit

# Verificar se o docker-compose.yml existe
ls -la docker-compose.yml

# Subir os serviços (API + PostgreSQL + Kafka)
docker-compose up -d

# Aguardar inicialização completa (30-60 segundos)
sleep 30
```

**Validação:**

```bash
# Verificar se os containers estão rodando
docker-compose ps

# Verificar logs do Kafka (deve mostrar "started")
docker-compose logs kafka | grep -i "started\|listening"

# Verificar logs da API (deve mostrar Spring Boot iniciado)
docker-compose logs api | grep -i "started\|listening"

# Verificar se o PostgreSQL está pronto
docker-compose logs postgres | grep -i "ready\|listening"

# Testar conectividade do Kafka
docker exec -it search-credit-kafka kafka-topics.sh --list --bootstrap-server localhost:9092
```

**Resultado esperado:**
- ✅ Todos os containers com status `Up`
- ✅ Kafka respondendo aos comandos
- ✅ API Spring Boot iniciada (verificar logs)
- ✅ PostgreSQL aceitando conexões

**Troubleshooting:**
- Se algum container não iniciar, verificar logs: `docker-compose logs <servico>`
- Se houver erro de porta, verificar se outra aplicação está usando a porta
- Se houver erro de rede, verificar se a rede foi criada corretamente

---

### Passo 3: Verificar Rede Docker e Conectividade

**Por que é necessário:** Garantir que o Kafka está acessível via DNS interno antes de iniciar o worker.

**Comandos:**

```bash
# Verificar se o Kafka está na rede correta
docker network inspect search-credit-network | grep -A 5 "search-credit-kafka"

# Testar resolução DNS do Kafka (deve retornar o IP)
docker run --rm --network search-credit-network \
  alpine/curl:latest \
  nslookup search-credit-kafka

# Verificar conectividade com o Kafka
docker run --rm --network search-credit-network \
  confluentinc/cp-kafka:latest \
  kafka-broker-api-versions --bootstrap-server search-credit-kafka:9092
```

**Resultado esperado:**
- ✅ Kafka visível na rede `search-credit-network`
- ✅ DNS resolve `search-credit-kafka` corretamente
- ✅ Kafka responde na porta 9092

**Troubleshooting:**
- Se o DNS não resolver, verificar se o container Kafka está na rede correta
- Se a conectividade falhar, verificar se o Kafka está realmente rodando

---

### Passo 4: Iniciar o credito-analise-worker

**Por que nesta ordem:** O worker depende do Kafka estar rodando e acessível via rede Docker.

**Comandos:**

```bash
# Navegar para o diretório do worker
cd ../credito-analise-worker

# Verificar configuração do docker-compose.yml
cat docker-compose.yml | grep -A 10 "worker:"

# Subir o worker
docker-compose up -d worker

# Aguardar inicialização (10-20 segundos)
sleep 15
```

**Validação:**

```bash
# Verificar se o container está rodando
docker-compose ps

# Verificar logs do worker (deve mostrar conexão com Kafka)
docker-compose logs worker | grep -i "kafka\|started\|listening"

# Verificar se o consumer está registrado no Kafka
docker exec -it search-credit-kafka \
  kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list | grep analise-group

# Verificar logs detalhados do worker
docker-compose logs -f worker
```

**Resultado esperado:**
- ✅ Container do worker com status `Up`
- ✅ Logs mostrando conexão bem-sucedida com Kafka
- ✅ Consumer group `analise-group` registrado no Kafka
- ✅ Sem erros de DNS ou conectividade

**Troubleshooting:**
- Se houver erro "No resolvable bootstrap urls", verificar:
  - Rede Docker está configurada corretamente
  - Kafka está na mesma rede
  - DNS resolve `search-credit-kafka`
- Se houver erro de conexão, verificar se o Kafka está realmente acessível

---

### Passo 5: Iniciar o search-credit-frontend

**Por que por último:** O frontend depende da API estar rodando e respondendo corretamente.

**Comandos:**

```bash
# Navegar para o diretório do frontend
cd ../search-credit-frontend

# Verificar se o docker-compose.yml existe
ls -la docker-compose.yml

# Subir o frontend
docker-compose up -d

# Aguardar inicialização (10-30 segundos dependendo do build)
sleep 20
```

**Validação:**

```bash
# Verificar se o container está rodando
docker-compose ps

# Verificar logs do frontend
docker-compose logs frontend | grep -i "started\|listening\|ready"

# Testar conectividade com a API
curl http://localhost:8080/actuator/health || echo "Verificar se a API está rodando"

# Verificar se o frontend está acessível
curl http://localhost:3000 || curl http://localhost:5173 || echo "Verificar porta do frontend"
```

**Resultado esperado:**
- ✅ Container do frontend com status `Up`
- ✅ Frontend acessível na porta configurada
- ✅ Sem erros de conexão com a API

**Troubleshooting:**
- Se o frontend não conseguir conectar à API, verificar:
  - API está rodando e acessível
  - Variáveis de ambiente do frontend apontam para a URL correta da API
  - Rede Docker está configurada corretamente

---

## 🔍 Validação Final do Ecossistema

Após todos os serviços estarem rodando, execute esta validação completa:

```bash
# 1. Verificar todos os containers rodando
echo "=== Containers Rodando ==="
docker ps --filter "name=search-credit" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=credito-analise-worker" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=search-credit-frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 2. Verificar rede Docker
echo -e "\n=== Rede Docker ==="
docker network inspect search-credit-network --format "{{range .Containers}}{{.Name}} {{end}}"

# 3. Verificar conectividade Kafka
echo -e "\n=== Kafka - Tópicos ==="
docker exec search-credit-kafka kafka-topics.sh --list --bootstrap-server localhost:9092

# 4. Verificar Consumer Groups
echo -e "\n=== Kafka - Consumer Groups ==="
docker exec search-credit-kafka kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# 5. Verificar saúde da API
echo -e "\n=== API Health ==="
curl -s http://localhost:8080/actuator/health | jq . || echo "API não respondeu"

# 6. Verificar logs recentes de erros
echo -e "\n=== Últimos Erros (últimas 5 linhas) ==="
docker-compose -f ../search-credit/docker-compose.yml logs --tail=5 | grep -i error || echo "Nenhum erro encontrado"
docker-compose -f ../credito-analise-worker/docker-compose.yml logs --tail=5 | grep -i error || echo "Nenhum erro encontrado"
```

**Resultado esperado:**
- ✅ Todos os containers com status `Up`
- ✅ Todos os serviços na rede `search-credit-network`
- ✅ Kafka com tópicos criados
- ✅ Consumer group `analise-group` registrado
- ✅ API respondendo corretamente
- ✅ Sem erros críticos nos logs

---

## 🛑 Ordem de Parada dos Serviços

Para parar os serviços na ordem inversa (evitando erros de dependência):

```bash
# 1. Parar o frontend (não tem dependentes)
cd ../search-credit-frontend
docker-compose down

# 2. Parar o worker (depende do Kafka)
cd ../credito-analise-worker
docker-compose down

# 3. Parar o search-credit (último, pois outros dependem dele)
cd ../search-credit
docker-compose down
```

**Nota:** A rede Docker `search-credit-network` não será removida automaticamente (é `external: true`). Para removê-la manualmente:

```bash
docker network rm search-credit-network
```

---

## 🔧 Comandos Úteis de Manutenção

### Ver logs de todos os serviços

```bash
# Logs do search-credit
cd ../search-credit && docker-compose logs -f

# Logs do worker
cd ../credito-analise-worker && docker-compose logs -f worker

# Logs do frontend
cd ../search-credit-frontend && docker-compose logs -f
```

### Reiniciar um serviço específico

```bash
# Reiniciar apenas o worker
cd ../credito-analise-worker
docker-compose restart worker

# Reiniciar apenas a API
cd ../search-credit
docker-compose restart api
```

### Verificar uso de recursos

```bash
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
```

### Limpar recursos (cuidado!)

```bash
# Remover apenas containers parados (não remove volumes)
docker container prune -f

# Remover apenas imagens não utilizadas (não remove imagens em uso)
docker image prune -f

# Remover apenas volumes não utilizados (cuidado: pode remover dados)
docker volume prune -f
```

**⚠️ Atenção:** Não use `docker system prune -a` sem entender o impacto. Ele pode remover volumes e imagens importantes.

---

## 📊 Diagrama de Dependências

```
┌─────────────────────────────────────┐
│   search-credit                     │
│   ┌──────────┐  ┌──────────┐       │
│   │PostgreSQL│  │  Kafka   │       │
│   └──────────┘  └──────────┘       │
│         │              │             │
│         └──────┬───────┘             │
│                │                     │
│         ┌──────▼──────┐              │
│         │  API REST   │              │
│         └────────────┘              │
└─────────────────────────────────────┘
         │                    │
         │                    │
    ┌────▼────┐        ┌─────▼──────┐
    │ Worker  │        │  Frontend  │
    │(Kafka)  │        │  (API)     │
    └─────────┘        └────────────┘
```

---

## ⚠️ Problemas Comuns e Soluções

### Problema: "No resolvable bootstrap urls"

**Causa:** Worker não consegue resolver o DNS do Kafka.

**Solução:**
```bash
# Verificar se a rede existe
docker network ls | grep search-credit-network

# Verificar se o Kafka está na rede
docker network inspect search-credit-network | grep search-credit-kafka

# Recriar a rede se necessário
docker network rm search-credit-network
docker network create search-credit-network

# Reiniciar os serviços na ordem correta
```

### Problema: "Connection refused" ao conectar na API

**Causa:** API não está rodando ou porta incorreta.

**Solução:**
```bash
# Verificar se a API está rodando
docker ps | grep search-credit-api

# Verificar logs da API
docker logs search-credit-api

# Verificar porta exposta
docker port search-credit-api
```

### Problema: Consumer não recebe mensagens

**Causa:** Consumer não está registrado ou tópico não existe.

**Solução:**
```bash
# Verificar consumer groups
docker exec search-credit-kafka \
  kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list

# Verificar tópicos
docker exec search-credit-kafka \
  kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092

# Verificar logs do worker
docker logs credito-analise-worker
```

---

## 📝 Resumo Rápido

**Ordem de inicialização:**
1. Criar rede Docker `search-credit-network`
2. Subir `search-credit` (API + PostgreSQL + Kafka)
3. Validar Kafka está acessível
4. Subir `credito-analise-worker`
5. Subir `search-credit-frontend`

**Comandos essenciais:**
```bash
# Criar rede
docker network create search-credit-network

# Subir search-credit
cd search-credit && docker-compose up -d

# Subir worker
cd credito-analise-worker && docker-compose up -d worker

# Subir frontend
cd search-credit-frontend && docker-compose up -d
```

---

**Última atualização:** 2024-12-22
**Versão:** 1.0

