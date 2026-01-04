package br.com.analise.creditoanaliseworker.consumer;

import br.com.analise.creditoanaliseworker.event.CreditoAnalisadoEvent;
import br.com.analise.creditoanaliseworker.producer.CreditoAnalisadoProducer;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.task.TaskExecutor;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.concurrent.ThreadLocalRandom;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
@Component
public class CreditoConsumer {

    private static final Pattern NUMERO_CREDITO_PATTERN = Pattern.compile("\\\"numeroCredito\\\"\\s*:\\s*\\\"([^\\\"]+)\\\"");
    private static final Pattern VALOR_ISSQN_PATTERN = Pattern.compile("\\\"valorIssqn\\\"\\s*:\\s*([0-9]+(?:\\.[0-9]+)?)");

    private final TaskExecutor creditoAnaliseExecutor;
    private final CreditoAnalisadoProducer creditoAnalisadoProducer;

    private final int simulacaoMinMs;
    private final int simulacaoRandomExtraMs;

    public CreditoConsumer(
            @Qualifier("creditoAnaliseExecutor") TaskExecutor creditoAnaliseExecutor,
            CreditoAnalisadoProducer creditoAnalisadoProducer,
            @Value("${credito.analise.simulacao.min-ms:2000}") int simulacaoMinMs,
            @Value("${credito.analise.simulacao.random-extra-ms:3000}") int simulacaoRandomExtraMs
    ) {
        this.creditoAnaliseExecutor = creditoAnaliseExecutor;
        this.creditoAnalisadoProducer = creditoAnalisadoProducer;
        this.simulacaoMinMs = simulacaoMinMs;
        this.simulacaoRandomExtraMs = simulacaoRandomExtraMs;
    }

    @KafkaListener(topics = "solicitacao-creditos-topic", groupId = "analise-group")
    public void consumirMensagem(String mensagem) {
        log.info("Recebido SolicitacaoCreditoEvent do tópico 'solicitacao-creditos-topic': {}", mensagem);

        creditoAnaliseExecutor.execute(() -> processarSimulacao(mensagem));
    }

    private void processarSimulacao(String mensagem) {
        String numeroCredito = extrairNumeroCredito(mensagem);
        Double valorIssqn = extrairValorIssqn(mensagem);

        simularTempoDeProcessamento();

        String resultado = decidirResultado(valorIssqn);
        log.info("Decisão sugerida para numeroCredito='{}': {}", numeroCredito, resultado);

        CreditoAnalisadoEvent event = new CreditoAnalisadoEvent(
                numeroCredito,
                resultado,
                "AUTO_WORKER",
                LocalDateTime.now()
        );

        creditoAnalisadoProducer.publicar(event);
        log.info("Publicado CreditoAnalisadoEvent no tópico 'credito-analisado-topic' para numeroCredito='{}'", numeroCredito);
    }

    private void simularTempoDeProcessamento() {
        int delayMs = simulacaoMinMs + ThreadLocalRandom.current().nextInt(Math.max(simulacaoRandomExtraMs, 1));
        try {
            Thread.sleep(delayMs);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private String decidirResultado(Double valorIssqn) {
        if (valorIssqn != null && valorIssqn < 1000d) {
            return ThreadLocalRandom.current().nextInt(100) < 70 ? "APROVADO" : "REPROVADO";
        }
        return ThreadLocalRandom.current().nextBoolean() ? "APROVADO" : "REPROVADO";
    }

    private String extrairNumeroCredito(String mensagem) {
        if (mensagem == null) {
            return "UNKNOWN";
        }
        Matcher matcher = NUMERO_CREDITO_PATTERN.matcher(mensagem);
        if (matcher.find()) {
            return matcher.group(1);
        }
        return "UNKNOWN";
    }

    private Double extrairValorIssqn(String mensagem) {
        if (mensagem == null) {
            return null;
        }
        Matcher matcher = VALOR_ISSQN_PATTERN.matcher(mensagem);
        if (matcher.find()) {
            try {
                return Double.parseDouble(matcher.group(1));
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }
}

