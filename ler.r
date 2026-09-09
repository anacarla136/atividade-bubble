ler_dados <- function(caminho) {
    dados <- scan(caminho, quiet = TRUE)
    return(dados)
}