bubblesort <- function (A, n) {
    for (i in 1:(n - 1)) {
        for (j in n:(i + 1)) {
            if (A[j] < A[j - 1]) {
                temp <- A[j]
                A[j] <- A[j - 1]
                A[j - 1] <- temp
            }
        }
    }
    return(A)
}