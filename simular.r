# carrega as funções dos outros arquivos
source("ler.r")
source("bubblesort.r")
source("verificar.r")
source("preparar.r")
source("escrever.r")

library(ggplot2)

# marca a hora que o script começou
inicio_total <- Sys.time()

# tamanhos que vão ser rodados de verdade
# o milhão não roda, ele é estimado lá embaixo
tamanhos <- c(1000, 10000, 100000)

# quantas repetições para cada tamanho
nr_por_tamanho <- c(
    "1000"    = 10,
    "10000"   = 10,
    "100000"  = 10
)

# tabela vazia onde cada tempo medido vai sendo guardado
resultados <- data.frame(n = integer(), rep = integer(), tempo = numeric())

for (tam in tamanhos) {
    cat("\n== Tamanho n =", tam, "==\n")

    # lê o arquivo de dados desse tamanho
    # format evita que 100000 vire 1e+05 no nome do arquivo
    A_original <- ler_dados(paste0("dados/", format(tam, scientific = FALSE), ".txt"))
    n <- length(A_original)
    nr <- nr_por_tamanho[[format(tam, scientific = FALSE, trim = TRUE)]]

    for (r in 1:nr) {
        # sempre começa do vetor bagunçado original
        A <- preparar(A_original)

        # mede só o tempo do bubblesort
        tempo_exec <- system.time({
            A <- bubblesort(A, n)
        })

        # se não ordenou direito o programa para
        if (!verificar(A)) {
            stop(paste("Problema na ordenacao! n =", tam, "rep =", r))
        }

        # mostra o tempo em segundos e em minutos
        cat("  rep", r, "de", nr, "-", tempo_exec[["elapsed"]], "s |",
            round(tempo_exec[["elapsed"]] / 60, 1), "min\n")

        # guarda o tempo dessa repetição
        resultados <- rbind(
            resultados,
            data.frame(n = tam, rep = r, tempo = tempo_exec[["elapsed"]])
        )

        # salva a cada repetição para não perder nada se o notebook desligar
        write.csv(resultados, "resultados_bubblesort_bruto.txt", row.names = FALSE)
    }
}

# média e desvio padrão do tempo de cada tamanho
resumo <- aggregate(tempo ~ n, data = resultados, FUN = function(x) {
    c(media = mean(x), desvio = sd(x))
})
resumo <- do.call(data.frame, resumo)
names(resumo) <- c("n", "tempo_medio", "tempo_desvio")
resumo$tempo_desvio[is.na(resumo$tempo_desvio)] <- 0

print(resumo)
write.csv(resumo, "resultados_bubblesort_resumo.txt", row.names = FALSE)

# parábola de grau 2, igual a linha de tendência da planilha do professor
modelo <- lm(tempo_medio ~ poly(n, 2, raw = TRUE), data = resumo)
r_quadrado <- summary(modelo)$r.squared

# coeficientes da fórmula ax² + bx + c
cf <- coef(modelo)
c0 <- cf[1]
b <- cf[2]
a <- cf[3]

formula_txt <- sprintf("f(x) = %.3e x² %+.3e x %+.3f\nR² = %.4f", a, b, c0, r_quadrado)
cat("\n", formula_txt, "\n")

# estimativa para 1.000.000 usando a fórmula, sem rodar o algoritmo
tempo_previsto_seg <- predict(modelo, newdata = data.frame(n = 1000000))

# tabela no formato da planilha do professor, com segundos, minutos e horas
tabela_final <- data.frame(
    n = c(resumo$n, 1000000),
    segundos = c(resumo$tempo_medio, tempo_previsto_seg),
    minutos = c(resumo$tempo_medio, tempo_previsto_seg) / 60,
    horas = c(resumo$tempo_medio, tempo_previsto_seg) / 3600
)
print(tabela_final)
write.csv(tabela_final, "tabela_final_com_estimativa.csv", row.names = FALSE)

# quadro de repetições, uma coluna por tamanho, para copiar na tabela do professor
tabela_reps <- data.frame(Repeticao = 1:10)
for (tam in tamanhos) {
    nome <- format(tam, big.mark = ".", scientific = FALSE)
    tabela_reps[[nome]] <- resultados$tempo[resultados$n == tam]
}
# o milhão fica vazio porque foi estimado
tabela_reps[["1.000.000"]] <- NA
write.csv(tabela_reps, "tabela_repeticoes.csv", row.names = FALSE)

# pontos da curva para desenhar a parábola no gráfico
curva_n <- seq(0, 100000, length.out = 200)
curva <- data.frame(n = curva_n, tempo = predict(modelo, newdata = data.frame(n = curva_n)))

# gráfico em escala normal, só com os pontos que foram medidos
grafico <- ggplot() +
    geom_line(data = curva, aes(x = n, y = tempo), color = "steelblue", linewidth = 0.8) +
    geom_point(data = resumo, aes(x = n, y = tempo_medio), color = "steelblue", size = 3) +
    annotate("text", x = 0, y = max(resumo$tempo_medio), label = formula_txt,
             hjust = 0, vjust = 1, size = 3.5) +
    labs(
        title = "Tempo de execucao do Bubblesort por tamanho de entrada",
        x = "Tamanho da entrada (n)",
        y = "Tempo medio (segundos)"
    ) +
    theme_minimal()

print(grafico)
ggsave("grafico_bubblesort.png", plot = grafico, width = 8, height = 5, dpi = 300)

cat("\nGrafico salvo em grafico_bubblesort.png\n")

# mostra quanto tempo o script inteiro levou
cat("\nTempo total do script:",
    round(as.numeric(difftime(Sys.time(), inicio_total, units = "mins")), 1),
    "minutos\n")