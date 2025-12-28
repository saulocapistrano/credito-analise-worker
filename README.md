# Credito Analise Worker - Serviço de Análise Assíncrona

Worker Kafka desenvolvido em Spring Boot para processamento assíncrono de eventos de consulta de créditos. Consome mensagens do tópico `consulta-creditos-topic` e processa eventos de forma assíncrona.

## Links dos Repositórios

- **Backend:** https://github.com/saulocapistrano/search-credit
- **Frontend:** https://github.com/saulocapistrano/search-credit-frontend
- **Worker (Este projeto):** https://github.com/saulocapistrano/credito-analise-worker

## Pré-requisitos Obrigatórios

- **Docker Desktop** instalado e **rodando**
- **Java 17+** (para compilação local, se necessário)
- **Maven 3.6+** (para compilação local, se necessário)

**Verificar Docker:**
```bash
docker ps
```

Se o comando acima falhar, inicie o Docker Desktop e aguarde até que esteja totalmente inicializado.

**Importante:** Este worker depende do serviço `search-credit` estar rodando, pois consome mensagens do Kafka gerenciado por aquele serviço.

## Comandos para Executar o Worker

```bash
# 1. Clone o repositório
git clone https://github.com/saulocapistrano/credito-analise-worker.git
cd credito-analise-worker

# 2. Criar rede Docker (se não existir)
docker network create search-credit-network

# 3. Compilar o projeto
./mvnw clean package

# 4. Subir o worker
docker compose up -d worker

# 5. Verificar logs do worker
docker compose logs -f worker
```

**Aguarde até ver:** `Successfully joined group` e `partitions assigned` nos logs, indicando que o consumer está conectado ao Kafka.

## Execução do Ecossistema Completo

Para testar o sistema completo (Backend + Worker + Frontend), execute os projetos abaixo na ordem indicada.

### Backend Spring Boot

```bash
git clone https://github.com/saulocapistrano/search-credit.git
cd search-credit
./mvnw clean package
docker compose up -d postgres zookeeper kafka kafka-ui
docker compose up -d search-credit
```

**Repositório:** https://github.com/saulocapistrano/search-credit

**Responsabilidades:**
- API REST para consulta de créditos
- Gerencia PostgreSQL e Kafka
- Publica eventos no tópico `consulta-creditos-topic`
- Porta: `8189`

**Acessar:** http://localhost:8189/swagger-ui.html

### Worker Kafka (Este Projeto)

```bash
git clone https://github.com/saulocapistrano/credito-analise-worker.git
cd credito-analise-worker
./mvnw clean package
docker compose up -d worker
```

**Repositório:** https://github.com/saulocapistrano/credito-analise-worker

**Responsabilidades:**
- Consome eventos Kafka do tópico `consulta-creditos-topic`
- Processa eventos de consulta de forma assíncrona
- Group ID: `analise-group`
- Porta: `8081`

### Frontend Angular (Opcional)

```bash
git clone https://github.com/saulocapistrano/search-credit-frontend.git
cd search-credit-frontend
docker compose up -d --build
```

**Repositório:** https://github.com/saulocapistrano/search-credit-frontend

**Responsabilidades:**
- Interface web para consulta de créditos
- Consulta por NFS-e ou número do crédito
- Tabela responsiva de resultados
- Porta: `4200`

**Acessar:** http://localhost:4200

## Execução do Worker Isoladamente

O worker pode ser executado isoladamente para desenvolvimento ou testes. A comunicação com o Kafka requer que o serviço `search-credit` esteja rodando e o Kafka esteja acessível via rede Docker.

### Desenvolvimento Local

Para desenvolvimento local, você pode sobrescrever a configuração do Kafka:

```bash
# Configurar Kafka local (se estiver rodando localmente)
export SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9095
./mvnw spring-boot:run
```

Ou executar o JAR diretamente:

```bash
java -jar target/credito-analise-worker-0.0.1-SNAPSHOT.jar
```

**Nota:** Para desenvolvimento local, certifique-se de que o Kafka está acessível na porta configurada ou ajuste a variável de ambiente `SPRING_KAFKA_BOOTSTRAP_SERVERS`.

## Funcionalidades Implementadas

### Consumo de Eventos Kafka

O worker consome mensagens do tópico `consulta-creditos-topic` publicadas pela API `search-credit`.

**Características:**
- Consumer group: `analise-group`
- Auto offset reset: `earliest` (processa desde o início se não houver offset salvo)
- Deserialização: String (mensagens JSON como texto)
- Processamento assíncrono de eventos
- Logging de todas as mensagens recebidas

**Fluxo de Processamento:**
1. API `search-credit` publica evento no tópico `consulta-creditos-topic`
2. Worker consome a mensagem automaticamente
3. Mensagem é logada para processamento futuro
4. Offset é commitado automaticamente após processamento

### Tópico Kafka

- **Nome:** `consulta-creditos-topic`
- **Formato:** Mensagens JSON como String
- **Producer:** `search-credit` (API)
- **Consumer:** `credito-analise-worker` (este projeto)

## Testes Automatizados

### Executar Testes

```bash
./mvnw clean test
```

**Cobertura:**
- Testes de integração do `CreditoConsumer` usando `@EmbeddedKafka`
- Testes de envio e consumo de mensagens Kafka
- JUnit 5 e Spring Kafka Test
- Testes isolados com Kafka embutido

**Testes implementados:**
- `deveConsumirMensagemDoTopico()` - Testa consumo de mensagem JSON
- `deveProcessarMensagemStringSimples()` - Testa consumo de mensagem simples

### Executar Testes com Cobertura

```bash
./mvnw clean test jacoco:report
```

## Tecnologias e Recursos

### Stack Tecnológico

- **Java 17**
- **Spring Boot 3.1.5**
- **Spring Kafka** - Integração com Apache Kafka
- **Apache Kafka** - Sistema de mensageria distribuída
- **Lombok** - Redução de boilerplate
- **Docker & Docker Compose** - Containerização
- **JUnit 5** - Testes unitários
- **Spring Kafka Test** - Testes de integração Kafka
- **Embedded Kafka** - Kafka embutido para testes

### Arquitetura

O projeto segue uma arquitetura simples e focada em consumo de mensagens:

- **Consumer**: Classe `CreditoConsumer` com `@KafkaListener`
- **Configuration**: Configurações via `application.yml`
- **Logging**: Logging estruturado com SLF4J e Lombok
- **Testes**: Testes de integração com Kafka embutido

### Comunicação Assíncrona

O worker consome eventos Kafka publicados pela API `search-credit`:

- **Consumer**: `credito-analise-worker` consome do tópico `consulta-creditos-topic`
- **Producer**: `search-credit` publica eventos JSON
- **Serialização**: String (JSON como texto)
- **Tópico**: `consulta-creditos-topic`
- **Group ID**: `analise-group`
- **Rede Docker**: Comunicação via rede compartilhada `search-credit-network`

### Padrões de Projeto

- **Consumer Pattern** - Consumo assíncrono de mensagens
- **Dependency Injection** - Injeção via Spring
- **Annotation-based Configuration** - Configuração via anotações Spring
- **Logging Pattern** - Logging estruturado de eventos

## Comandos Úteis

### Verificar Status do Serviço

```bash
docker compose ps
```

### Ver Logs

```bash
docker compose logs -f worker
```

### Parar o Serviço

```bash
docker compose down
```

### Reiniciar o Serviço

```bash
docker compose restart worker
```

### Verificar Consumer Groups no Kafka

```bash
docker exec search-credit-kafka \
  kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### Verificar Offset do Consumer Group

```bash
docker exec search-credit-kafka \
  kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group analise-group \
  --describe
```

### Enviar Mensagem de Teste para o Tópico

```bash
docker exec -it search-credit-kafka \
  kafka-console-producer.sh \
  --broker-list localhost:9092 \
  --topic consulta-creditos-topic
```

Digite uma mensagem JSON e pressione Enter. A mensagem será consumida pelo worker e aparecerá nos logs.

### Verificar Tópicos Kafka

```bash
docker exec search-credit-kafka \
  kafka-topics.sh \
  --list \
  --bootstrap-server localhost:9092
```

## Troubleshooting

### Docker Desktop não está rodando

**Sintoma:** `Cannot connect to the Docker daemon`

**Solução:** Inicie o Docker Desktop e aguarde até que esteja totalmente inicializado.

### Worker não consegue conectar ao Kafka

**Sintoma:** `No resolvable bootstrap urls` ou `Couldn't resolve server search-credit-kafka:9092`

**Soluções:**
1. Verificar se o Kafka está rodando: `docker ps | grep search-credit-kafka`
2. Verificar se estão na mesma rede Docker: `docker network inspect search-credit-network`
3. Verificar se o nome do container Kafka está correto: `search-credit-kafka`
4. Aguardar Kafka inicializar completamente (10-30 segundos após subir)
5. Verificar logs do Kafka: `docker compose -f ../search-credit/docker-compose.yml logs kafka`

### Consumer não recebe mensagens

**Sintoma:** Mensagens publicadas não aparecem nos logs do worker

**Soluções:**
1. Verificar se o consumer group está registrado:
   ```bash
   docker exec search-credit-kafka \
     kafka-consumer-groups.sh \
     --bootstrap-server localhost:9092 \
     --list | grep analise-group
   ```
2. Verificar se o tópico existe:
   ```bash
   docker exec search-credit-kafka \
     kafka-topics.sh \
     --list \
     --bootstrap-server localhost:9092 | grep consulta-creditos-topic
   ```
3. Verificar logs do worker para erros: `docker compose logs worker`
4. Verificar offset do consumer group (pode estar em offset antigo)

### Rede Docker não existe

**Sintoma:** `network search-credit-network not found`

**Solução:**
```bash
docker network create search-credit-network
```

### Porta já está em uso

**Sintoma:** `Bind for 0.0.0.0:8081 failed: port is already allocated`

**Solução:** Identifique e pare o processo usando a porta ou altere a porta no `docker-compose.yml`.

### Kafka não está acessível via DNS

**Sintoma:** Worker não consegue resolver `search-credit-kafka`

**Soluções:**
1. Verificar se o Kafka está na rede correta:
   ```bash
   docker network inspect search-credit-network | grep search-credit-kafka
   ```
2. Verificar configuração do `KAFKA_CFG_ADVERTISED_LISTENERS` no docker-compose do search-credit (deve ser `PLAINTEXT://search-credit-kafka:9092`)
3. Reiniciar o Kafka após ajustar configurações:
   ```bash
   cd ../search-credit
   docker compose restart kafka
   ```

## Estrutura do Projeto

```
credito-analise-worker/
├── src/
│   ├── main/
│   │   ├── java/br/com/analise/creditoanaliseworker/
│   │   │   ├── consumer/                    # Consumidores Kafka
│   │   │   │   └── CreditoConsumer.java    # Kafka Listener principal
│   │   │   └── CreditoAnaliseWorkerApplication.java
│   │   └── resources/
│   │       └── application.yml             # Configurações Kafka
│   └── test/
│       └── java/br/com/analise/creditoanaliseworker/
│           └── consumer/
│               └── CreditoConsumerTest.java # Testes de integração
├── docker-compose.yml                       # Configuração do worker
├── Dockerfile                               # Imagem Docker da aplicação
├── pom.xml                                  # Dependências Maven
└── README.md
```

## Configuração

### Tópico Kafka

- **Nome:** `consulta-creditos-topic`
- **Group ID:** `analise-group`
- **Bootstrap Servers:** `search-credit-kafka:9092` (via rede Docker)

### Portas

- **Aplicação:** `8081`
- **Kafka:** Conecta via rede Docker ao serviço `search-credit-kafka:9092`

### Rede Docker

- **Rede:** `search-credit-network` (external: true)
- O worker deve estar na mesma rede que o Kafka do serviço `search-credit`
- Comunicação via DNS interno do Docker (`search-credit-kafka`)

### Variáveis de Ambiente

Você pode sobrescrever configurações via variáveis de ambiente:

```bash
export SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka-host:9092
export SPRING_KAFKA_CONSUMER_GROUP_ID=meu-group-id
```

## Verificação de Saúde

Para verificar se o serviço está rodando e consumindo mensagens:

1. Verifique os logs da aplicação: `docker compose logs worker`
2. Verifique se o consumer group está registrado no Kafka
3. Envie uma mensagem de teste para o tópico
4. Confirme que a mensagem aparece nos logs do worker

**Logs esperados quando funcionando corretamente:**
```
INFO - Successfully joined group with generation
INFO - partitions assigned: [consulta-creditos-topic-0]
INFO - Mensagem recebida do tópico 'consulta-creditos-topic': {mensagem}
```

## Guia de Inicialização Completo

Para instruções detalhadas sobre inicialização do ambiente Docker completo (Backend + Worker + Frontend), consulte o [Guia de Inicialização Docker](GUIA_INICIALIZACAO.md).
