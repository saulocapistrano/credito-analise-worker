package br.com.analise.creditoanaliseworker.event;

import java.time.LocalDateTime;

public record CreditoAnalisadoEvent(
        String numeroCredito,
        String resultado,
        String analisadoPor,
        LocalDateTime dataHora
) {
}
