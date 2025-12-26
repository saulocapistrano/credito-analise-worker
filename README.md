# Credito Analise Worker

Serviço assíncrono de mensageria Kafka para análise de crédito. Este worker consome mensagens do tópico `consulta-creditos-topic` e processa eventos de consulta de crédito de forma assíncrona.

## 📋 Descrição

O `credito-analise-worker` é um microsserviço Spring Boot que atua como consumidor Kafka, recebendo e processando mensagens do sistema principal `search-credit`. O serviço foi projetado para rodar de forma **independente e dockerizada**.

### Características

- ✅ Consome mensagens do tópico Kafka `consulta-creditos-topic`
- ✅ Group ID: `analise-group`
- ✅ Porta da aplicação: `8081`
- ✅ Conecta ao Kafka via rede Docker (`search-credit-kafka:9092`)
- ✅ Totalmente dockerizado e pronto para produção

## 🚀 Como Executar

### Pré-requisitos

- Java 17+
- Maven 3.6+
- Docker e Docker Compose
- Rede Docker `search-credit-network` criada e Kafka do serviço `search-credit` rodando

### Opção 1: Executar com Docker Compose (Produção)

1. **Garantir que a rede Docker existe:**
   ```bash
   docker network create search-credit-network
   ```
   (Ou verificar se já existe se o serviço `search-credit` já está rodando)

2. **Compilar o projeto:**
   ```bash
   mvn clean package
   ```

3. **Subir o worker:**
   ```bash
   docker-compose up -d worker
   ```

4. **Verificar logs:**
   ```bash
   docker-compose logs -f worker
   ```

### Opção 2: Executar localmente com Maven (Desenvolvimento)

Para desenvolvimento local, você pode sobrescrever a configuração do Kafka:

```bash
export SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9095
mvn spring-boot:run
```

Ou executar o JAR diretamente:
```bash
java -jar target/credito-analise-worker-0.0.1-SNAPSHOT.jar
```

## 🐳 Docker

### Gerar a imagem Docker

```bash
mvn clean package
docker build -t credito-analise-worker:latest .
```

### Executar o container manualmente

```bash
docker run -p 8081:8081 \
  --network search-credit-network \
  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=search-credit-kafka:9092 \
  credito-analise-worker:latest
```

**Importante:** O container deve estar na mesma rede Docker (`search-credit-network`) que o Kafka do serviço `search-credit`.

## 🧪 Como Testar

### Enviar mensagem de teste via Kafka Console Producer

Com o Kafka do serviço `search-credit` rodando:

```bash
# Entrar no container do Kafka do search-credit
docker exec -it search-credit-kafka bash

# Enviar mensagem para o tópico
kafka-console-producer.sh \
  --broker-list search-credit-kafka:9092 \
  --topic consulta-creditos-topic
```

Digite uma mensagem e pressione Enter. A mensagem será consumida pelo worker e aparecerá nos logs.

### Enviar mensagem via Docker (sem entrar no container)

```bash
docker exec -it search-credit-kafka \
  kafka-console-producer.sh \
  --broker-list search-credit-kafka:9092 \
  --topic consulta-creditos-topic
```

### Verificar logs do consumer

Os logs do worker mostrarão:
```
INFO  - Mensagem recebida do tópico 'consulta-creditos-topic': {sua mensagem}
```

### Executar testes automatizados

```bash
mvn test
```

## 📁 Estrutura do Projeto

```
credito-analise-worker/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── br/com/analise/creditoanaliseworker/
│   │   │       ├── consumer/
│   │   │       │   └── CreditoConsumer.java    # Kafka Listener
│   │   │       └── CreditoAnaliseWorkerApplication.java
│   │   └── resources/
│   │       └── application.yml                 # Configurações Kafka
│   └── test/
│       └── java/
│           └── br/com/analise/creditoanaliseworker/
│               └── consumer/
│                   └── CreditoConsumerTest.java # Testes automatizados
├── docker-compose.yml                           # Configuração do worker
├── Dockerfile                                   # Imagem Docker da aplicação
└── pom.xml
```

## ⚙️ Configuração

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

### Variáveis de Ambiente

Você pode sobrescrever configurações via variáveis de ambiente:

```bash
export SPRING_KAFKA_BOOTSTRAP_SERVERS=kafka-host:9092
export SPRING_KAFKA_CONSUMER_GROUP_ID=meu-group-id
```

## 🔍 Verificação de Saúde

Para verificar se o serviço está rodando e consumindo mensagens:

1. Verifique os logs da aplicação
2. Envie uma mensagem de teste para o tópico
3. Confirme que a mensagem aparece nos logs

## 📝 Desenvolvimento

### Compilar

```bash
mvn clean compile
```

### Executar testes

```bash
mvn test
```

### Build completo

```bash
mvn clean package
```

## 🛠️ Tecnologias

- **Spring Boot 3.1.5**
- **Spring Kafka**
- **Java 17**
- **Lombok**
- **Maven**
- **Docker & Docker Compose**
- **Apache Kafka**

## 📄 Licença

Este projeto faz parte do ecossistema de crédito.

---

**Desenvolvido para avaliação técnica** 🚀

