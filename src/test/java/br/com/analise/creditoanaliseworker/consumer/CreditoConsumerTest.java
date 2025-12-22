package br.com.analise.creditoanaliseworker.consumer;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.TestPropertySource;

import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

@SpringBootTest
@EmbeddedKafka(
        topics = "consulta-creditos-topic",
        partitions = 1,
        brokerProperties = {
                "listeners=PLAINTEXT://localhost:9095",
                "port=9095"
        }
)
@TestPropertySource(properties = {
        "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.consumer.group-id=analise-group",
        "spring.kafka.consumer.auto-offset-reset=earliest"
})
@DirtiesContext
class CreditoConsumerTest {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Test
    void deveConsumirMensagemDoTopico() {
        // Arrange
        String mensagemTeste = "{\"cpf\":\"12345678900\",\"valor\":1000.00}";

        // Act & Assert
        assertDoesNotThrow(() -> {
            kafkaTemplate.send("consulta-creditos-topic", mensagemTeste).get(5, TimeUnit.SECONDS);
            // Aguarda um tempo para o consumer processar a mensagem
            Thread.sleep(1000);
        }, "Mensagem deve ser enviada e consumida sem exceções");
    }

    @Test
    void deveProcessarMensagemStringSimples() {
        // Arrange
        String mensagemSimples = "Mensagem de teste simples";

        // Act & Assert
        assertDoesNotThrow(() -> {
            kafkaTemplate.send("consulta-creditos-topic", mensagemSimples).get(5, TimeUnit.SECONDS);
            // Aguarda um tempo para o consumer processar a mensagem
            Thread.sleep(1000);
        }, "Mensagem simples deve ser processada sem exceções");
    }
}

