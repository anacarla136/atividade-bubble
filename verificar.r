verificar <- function(A) {
    n <- length(A)
    for (i in 1:(n - 1)) {
        if (A[i] > A[i + 1]) {
            return(FALSE)
        }
    }
    return(TRUE)
}