package br.com.analise.creditoanaliseworker.consumer;

import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class CreditoConsumer {

    @KafkaListener(topics = "consulta-creditos-topic", groupId = "analise-group")
    public void consumirMensagem(String mensagem) {
        log.info("Mensagem recebida do tópico 'consulta-creditos-topic': {}", mensagem);
        // Processamento mínimo: apenas logar a mensagem recebida
    }
}

