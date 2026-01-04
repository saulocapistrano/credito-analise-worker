package br.com.analise.creditoanaliseworker.producer;

import br.com.analise.creditoanaliseworker.event.CreditoAnalisadoEvent;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

import java.time.format.DateTimeFormatter;

@Component
public class CreditoAnalisadoProducer {

    public static final String TOPIC = "credito-analisado-topic";

    private final KafkaTemplate<String, String> kafkaTemplate;

    public CreditoAnalisadoProducer(KafkaTemplate<String, String> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    public void publicar(CreditoAnalisadoEvent event) {
        kafkaTemplate.send(TOPIC, event.numeroCredito(), toJson(event));
    }

    private String toJson(CreditoAnalisadoEvent event) {
        String dataHora = event.dataHora() == null
                ? null
                : event.dataHora().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);

        return "{" +
                "\"numeroCredito\":\"" + escape(event.numeroCredito()) + "\"," +
                "\"resultado\":\"" + escape(event.resultado()) + "\"," +
                "\"analisadoPor\":\"" + escape(event.analisadoPor()) + "\"," +
                "\"dataHora\":" + (dataHora == null ? "null" : "\"" + dataHora + "\"") +
                "}";
    }

    private String escape(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
