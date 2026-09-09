source("ler.r")
source("bubblesort.r")
source("verificar.r")
source("preparar.r")
source("escrever.r")

library(ggplot2)

# ---- 1. Configuração ----
tamanhos <- c(1000, 10000, 100000, 1000000)

# Número de repetições por tamanho. Reduzido para os tamanhos maiores porque
# bubblesort é O(n^2): rodar n = 1.000.000 trinta vezes pode ser inviável.
# Ajuste esses valores conforme o tempo disponível.
nr_por_tamanho <- c(
    "1000"    = 30,
    "10000"   = 30,
    "100000"  = 10,
    "1000000" = 3
)

# ---- 2. Loop de medição ----
resultados <- data.frame(n = integer(), rep = integer(), tempo = numeric())

for (tam in tamanhos) {
    cat("\n== Tamanho n =", tam, "==\n")

    A_original <- ler_dados(paste0("dados/", tam, ".txt"))
    n <- length(A_original)
    nr <- nr_por_tamanho[[as.character(tam)]]

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

# ---- 5. Gráfico ----
# Escala log-log: com n variando de mil a um milhao (3 ordens de grandeza),
# o log-log deixa visivel que o crescimento e quadratico (reta de inclinacao ~2).
grafico <- ggplot(resumo, aes(x = n, y = tempo_medio)) +
    geom_line(color = "steelblue", linewidth = 1) +
    geom_point(color = "steelblue", size = 3) +
    geom_errorbar(
        aes(ymin = tempo_medio - tempo_desvio, ymax = tempo_medio + tempo_desvio),
        width = 0.05, color = "steelblue", alpha = 0.5
    ) +
    scale_x_log10() +
    scale_y_log10() +
    labs(
        title = "Tempo de execucao do Bubblesort por tamanho de entrada",
        subtitle = paste0("Media de repeticoes por tamanho, escala log-log"),
        x = "Tamanho da entrada (n) - escala log",
        y = "Tempo medio (segundos) - escala log"
    ) +
    theme_minimal()

print(grafico)

ggsave("grafico_bubblesort.png", plot = grafico, width = 8, height = 5, dpi = 300)

cat("\nGrafico salvo em grafico_bubblesort.png\n")
