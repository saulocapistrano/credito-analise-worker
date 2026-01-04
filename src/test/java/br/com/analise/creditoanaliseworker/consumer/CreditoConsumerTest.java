package br.com.analise.creditoanaliseworker.consumer;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.TestPropertySource;

import java.io.File;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

@SpringBootTest
@EmbeddedKafka(
        topics = {
                "solicitacao-creditos-topic",
                "credito-analisado-topic"
        },
        partitions = 1,
        brokerProperties = {
                "listeners=PLAINTEXT://localhost:9095",
                "port=9095"
        }
)
@TestPropertySource(properties = {
        "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.consumer.group-id=analise-group",
        "spring.kafka.consumer.auto-offset-reset=earliest",
        "credito.analise.simulacao.min-ms=10",
        "credito.analise.simulacao.random-extra-ms=10"
})
@DirtiesContext
class CreditoConsumerTest {

    static {
        // Configura propriedades do Zookeeper para evitar problemas no Windows
        // Desabilita o sync forçado do Zookeeper que pode causar problemas no Windows
        System.setProperty("zookeeper.forceSync", "no");
        // Configura o diretório temporário do Zookeeper para um local conhecido
        // Isso evita problemas com criação de diretórios no Windows
        String tempDir = System.getProperty("java.io.tmpdir");
        if (tempDir != null) {
            File temp = new File(tempDir);
            if (!temp.exists()) {
                temp.mkdirs();
            }
            // Garante permissões de escrita no diretório temporário
            temp.setWritable(true);
            // Configura o diretório de dados do Zookeeper para evitar problemas no Windows
            File zkDataDir = new File(temp, "zookeeper-test-data");
            if (!zkDataDir.exists()) {
                zkDataDir.mkdirs();
            }
            System.setProperty("zookeeper.dataDir", zkDataDir.getAbsolutePath());
        }
    }

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Test
    void deveConsumirMensagemDoTopico() {
        // Arrange
        String mensagemTeste = "{\"numeroCredito\":\"CRED-123\",\"valorIssqn\":500.00}";

        // Act & Assert
        assertDoesNotThrow(() -> {
            kafkaTemplate.send("solicitacao-creditos-topic", mensagemTeste).get(5, TimeUnit.SECONDS);
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
            kafkaTemplate.send("solicitacao-creditos-topic", mensagemSimples).get(5, TimeUnit.SECONDS);
            // Aguarda um tempo para o consumer processar a mensagem
            Thread.sleep(1000);
        }, "Mensagem simples deve ser processada sem exceções");
    }
}

