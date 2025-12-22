# Credito Analise Worker

Serviço assíncrono de mensageria Kafka para análise de crédito. Este worker consome mensagens do tópico `consulta-creditos-topic` e processa eventos de consulta de crédito de forma assíncrona.

## 📋 Descrição

O `credito-analise-worker` é um microsserviço Spring Boot que atua como consumidor Kafka, recebendo e processando mensagens do sistema principal `search-credit`. O serviço foi projetado para rodar de forma **independente e dockerizada**.

### Características

- ✅ Consome mensagens do tópico Kafka `consulta-creditos-topic`
- ✅ Group ID: `analise-group`
- ✅ Porta da aplicação: `8081`
- ✅ Kafka configurado na porta `localhost:9095`
- ✅ Totalmente dockerizado e pronto para produção

## 🚀 Como Executar

### Pré-requisitos

- Java 17+
- Maven 3.6+
- Docker e Docker Compose (para execução com Kafka local)

### Opção 1: Executar com Docker Compose (Recomendado)

1. **Subir o Kafka e Zookeeper:**
   ```bash
   docker-compose up -d
   ```

2. **Compilar o projeto:**
   ```bash
   mvn clean package
   ```

3. **Executar a aplicação:**
   ```bash
   mvn spring-boot:run
   ```

   Ou executar o JAR diretamente:
   ```bash
   java -jar target/credito-analise-worker-0.0.1-SNAPSHOT.jar
   ```

### Opção 2: Executar apenas com Maven (requer Kafka externo)

Se você já tem um Kafka rodando em `localhost:9095`:

```bash
mvn spring-boot:run
```

## 🐳 Docker

### Gerar a imagem Docker

```bash
mvn clean package
docker build -t credito-analise-worker:latest .
```

### Executar o container

```bash
docker run -p 8081:8081 \
  -e SPRING_KAFKA_BOOTSTRAP_SERVERS=localhost:9095 \
  credito-analise-worker:latest
```

**Nota:** Se o Kafka estiver rodando em outro host, ajuste a variável de ambiente `SPRING_KAFKA_BOOTSTRAP_SERVERS`.

## 🧪 Como Testar

### Enviar mensagem de teste via Kafka Console Producer

Com o Kafka rodando via Docker Compose:

```bash
# Entrar no container do Kafka
docker exec -it credito-analise-worker-kafka-1 bash

# Enviar mensagem para o tópico
kafka-console-producer.sh \
  --broker-list localhost:9092 \
  --topic consulta-creditos-topic
```

Digite uma mensagem e pressione Enter. A mensagem será consumida pelo worker e aparecerá nos logs.

### Enviar mensagem via Docker (sem entrar no container)

```bash
docker exec -it credito-analise-worker-kafka-1 \
  kafka-console-producer.sh \
  --broker-list localhost:9092 \
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
├── docker-compose.yml                           # Kafka + Zookeeper
├── Dockerfile                                   # Imagem Docker da aplicação
└── pom.xml
```

## ⚙️ Configuração

### Tópico Kafka
- **Nome:** `consulta-creditos-topic`
- **Group ID:** `analise-group`
- **Bootstrap Servers:** `localhost:9095`

### Portas
- **Aplicação:** `8081`
- **Kafka:** `9095` (mapeado de `9092` interno)
- **Zookeeper:** `2181`

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

