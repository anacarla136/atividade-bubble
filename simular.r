source("ler.r")
source("bubblesort.r")
source("verificar.r")
source("preparar.r")
source("escrever.r")

A_original <- ler_dados("dados/1000.txt")
n <- length(A_original)
nr <- 30

for (r in 1:nr) {
    A <- preparar(A_original)
    A <- bubblesort(A, n)
    if (!verificar(A)) {
        stop("Problema na ordenação!")
    }
}

print(A)