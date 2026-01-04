# Credito Análise Worker — Processamento Assíncrono de Decisão

Worker Kafka desenvolvido em **Spring Boot** para **simular decisões automáticas de crédito** de forma assíncrona.

⚠️ Este serviço **não realiza análise real de crédito**.

Seu objetivo é **demonstrar um pipeline assíncrono orientado a eventos**.

---

## Objetivo Arquitetural

Demonstrar domínio sobre:
- Event-Driven Architecture
- Processamento assíncrono
- Separação de responsabilidades
- Idempotência em consumidores Kafka
- Evolução arquitetural sem acoplamento

---

## O que o Worker Faz

- Consome `SolicitacaoCreditoEvent` do tópico `solicitacao-creditos-topic`
- Simula tempo de processamento
- Decide **APROVADO** ou **REPROVADO** (simulação)
- Publica `CreditoAnalisadoEvent` no tópico `credito-analisado-topic`
- Não acessa banco
- Não altera estado diretamente

---

## O que o Worker NÃO Faz

❌ Não persiste dados  
❌ Não acessa repositórios  
❌ Não chama APIs REST  
❌ Não implementa regras reais de crédito  

A **API é a única dona do estado**.

---

## Fluxo

`SolicitacaoCreditoEvent`
↓
`credito-analise-worker`
↓
(simulação simples)
↓
`CreditoAnalisadoEvent`
↓
Kafka

 A API decide se aplica ou ignora o evento.

## Links dos Repositórios

- **Backend:** https://github.com/saulocapistrano/search-credit
- **Frontend:** https://github.com/saulocapistrano/search-credit-frontend
- **Worker (Este projeto):** https://github.com/saulocapistrano/credito-analise-worker

---

## Execução

```bash
git clone https://github.com/saulocapistrano/credito-analise-worker.git
cd credito-analise-worker
./mvnw clean package

docker network create search-credit-network
docker compose up -d
```

---

## Comportamento Esperado

O serviço roda silenciosamente.

Não possui endpoints HTTP.

O efeito é percebido apenas:

- Nos logs
- No Kafka UI
- Na mudança posterior de status do crédito (quando a API decidir aplicar o evento)

Esse comportamento reflete sistemas distribuídos reais.

---

## Logs esperados

```
INFO - Successfully joined group with generation
INFO - partitions assigned: [solicitacao-creditos-topic-0]
INFO - Recebido SolicitacaoCreditoEvent do tópico 'solicitacao-creditos-topic': {mensagem}
INFO - Decisão sugerida para numeroCredito='{...}': {APROVADO|REPROVADO}
INFO - Publicado CreditoAnalisadoEvent no tópico 'credito-analisado-topic' para numeroCredito='{...}'
```

---

## Stack

- Java 17
- Spring Boot
- Spring Kafka
- Apache Kafka
- Docker
- JUnit 5

---

## Guia de Inicialização Completo

Para instruções detalhadas sobre inicialização do ambiente Docker completo (Backend + Worker + Frontend), consulte o [Guia de Inicialização Docker](GUIA_INICIALIZACAO.md).
