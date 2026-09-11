source("ler.r")
source("bubblesort.r")
source("verificar.r")
source("preparar.r")
source("escrever.r")

library(ggplot2)

# ---- 1. Configuração ----
tamanhos <- c(1000, 10000, 100000)

# Número de repetições por tamanho. Reduzido para os tamanhos maiores porque
# bubblesort é O(n^2): rodar n = 1.000.000 trinta vezes pode ser inviável.
# Ajuste esses valores conforme o tempo disponível.
nr_por_tamanho <- c(
    "1000" = 30,
    "10000" = 10,
    "100000" = 1
)

# ---- 2. Loop de medição ----
resultados <- data.frame(n = integer(), rep = integer(), tempo = numeric())

for (tam in tamanhos) {
    cat("\n== Tamanho n =", tam, "==\n")

    A_original <- ler_dados(paste0("dados/", format(tam, scientific = FALSE), ".txt"))
    n <- length(A_original)
    nr <- nr_por_tamanho[[format(tam, scientific = FALSE, trim = TRUE)]]

    for (r in 1:nr) {
        A <- preparar(A_original)

        tempo_exec <- system.time({
            A <- bubblesort(A, n)
        })

        if (!verificar(A)) {
            stop(paste("Problema na ordenacao! n =", tam, "rep =", r))
        }

        cat("  rep", r, "de", nr, "-", tempo_exec[["elapsed"]], "s\n")

        resultados <- rbind(
            resultados,
            data.frame(n = tam, rep = r, tempo = tempo_exec[["elapsed"]])
        )
    }
}

# ---- 3. Salvar resultados brutos (todas as repetições) ----
write.csv(resultados, "resultados_bubblesort_bruto.txt", row.names = FALSE)

# ---- 4. Agregar: média e desvio padrão do tempo por tamanho ----
resumo <- aggregate(tempo ~ n, data = resultados, FUN = function(x) {
    c(media = mean(x), desvio = sd(x))
})
resumo <- do.call(data.frame, resumo)
names(resumo) <- c("n", "tempo_medio", "tempo_desvio")
resumo$tempo_desvio[is.na(resumo$tempo_desvio)] <- 0 # caso de 1 repeticao so

print(resumo)
write.csv(resumo, "resultados_bubblesort_resumo.txt", row.names = FALSE)

# ---- 4.5. Extrapolação para 1.000.000 (não executado por inviabilidade de tempo) ----
modelo <- lm(log10(tempo_medio) ~ log10(n), data = resumo)
log_tempo_previsto <- predict(modelo, newdata = data.frame(n = 1000000))
tempo_previsto_seg <- 10^log_tempo_previsto
tempo_previsto_horas <- tempo_previsto_seg / 3600

cat("\nEstimativa para n = 1.000.000 (extrapolação, não executado):\n")
cat("  Tempo previsto:", round(tempo_previsto_seg, 0), "segundos\n")
cat("  Equivalente a: ", round(tempo_previsto_horas, 1), "horas\n")

extrapolado <- data.frame(
  n = 1000000,
  tempo_medio = tempo_previsto_seg,
  tempo_desvio = 0,
  tipo = "Extrapolado"
)
resumo$tipo <- "Medido"
resumo_completo <- rbind(resumo, extrapolado)

# ---- 5. Gráfico ----
# Escala log-log: com n variando de mil a um milhao (3 ordens de grandeza),
# o log-log deixa visivel que o crescimento e quadratico (reta de inclinacao ~2).
grafico <- ggplot(resumo_completo, aes(x = n, y = tempo_medio)) +
  geom_line(color = "steelblue", linewidth = 1) +
  geom_point(aes(color = tipo, shape = tipo), size = 4) +
  geom_errorbar(
    data = subset(resumo_completo, tipo == "Medido"),
    aes(ymin = tempo_medio - tempo_desvio, ymax = tempo_medio + tempo_desvio),
    width = 0.05, color = "steelblue", alpha = 0.5
  ) +
  scale_x_log10() +
  scale_y_log10() +
  scale_color_manual(values = c("Medido" = "steelblue", "Extrapolado" = "firebrick")) +
  labs(
    title = "Tempo de execucao do Bubblesort por tamanho de entrada",
    subtitle = "Pontos medidos (azul) + extrapolacao matematica para 1M (vermelho)",
    x = "Tamanho da entrada (n) - escala log",
    y = "Tempo medio (segundos) - escala log",
    color = "Tipo de dado",
    shape = "Tipo de dado"
  ) +
  theme_minimal()

print(grafico)

ggsave("grafico_bubblesort.png", plot = grafico, width = 8, height = 5, dpi = 300)

cat("\nGrafico salvo em grafico_bubblesort.png\n")
