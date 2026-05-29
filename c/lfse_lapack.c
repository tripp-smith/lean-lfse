/* lfse_lapack.c
 * Thin pass-through wrappers around a system LAPACK (liblapacke or compatible).
 * Build with -llapacke -llapack -lblas (or distro equivalent).
 * All arrays column-major. See header for semantics.
 * Part of the LSMC formal upgrade (spec T-005 / F-02).
 */
#include "lfse_lapack.h"
#include <string.h>

/* Many distros provide the reference LAPACK with these symbols directly.
 * On some systems (e.g. via OpenBLAS or MKL), the names are the same.
 * We use the minimal subset needed for normal equations + prediction.
 */
extern int dposv_(const char *uplo, const int *n, const int *nrhs,
                  double *a, const int *lda, double *b, const int *ldb, int *info);

extern int dgels_(const char *trans, const int *m, const int *n, const int *nrhs,
                  double *a, const int *lda, double *b, const int *ldb,
                  double *work, const int *lwork, int *info);

extern void dgemv_(const char *trans, const int *m, const int *n,
                   const double *alpha, const double *a, const int *lda,
                   const double *x, const int *incx, const double *beta,
                   double *y, const int *incy);

int lfse_dposv(int n, int nrhs, double *A, double *B) {
    if (n <= 0 || nrhs <= 0) return -1;
    char uplo = 'U'; /* upper triangle */
    int lda = n;
    int ldb = n;
    int info = 0;
    /* dposv_ expects 1-based Fortran indexing semantics; we pass pointers directly */
    dposv_(&uplo, &n, &nrhs, A, &lda, B, &ldb, &info);
    return info;
}

int lfse_dgels(int m, int n, int nrhs, double *A, double *B) {
    if (m <= 0 || n <= 0 || nrhs <= 0) return -1;
    char trans = 'N'; /* A is m x n, solve A*X ~ B */
    int lda = m;
    int ldb = (m > n ? m : n); /* leading dim of B as per LAPACK */
    int lwork = -1;
    double wkopt = 0.0;
    int info = 0;

    /* Query optimal workspace */
    dgels_(&trans, &m, &n, &nrhs, A, &lda, B, &ldb, &wkopt, &lwork, &info);
    if (info != 0) return info;
    lwork = (int)wkopt;
    if (lwork < 1) lwork = 1;

    /* Allocate temp workspace on stack for small m (LSMC m<=8 typical) */
    double work[256];
    if (lwork > 256) {
        /* Fallback: caller should ensure small problems or provide larger buffer.
           For the LSMC use case (m<=8, nrhs=1) this is never hit. */
        return -2;
    }
    dgels_(&trans, &m, &n, &nrhs, A, &lda, B, &ldb, work, &lwork, &info);
    return info;
}

void lfse_dgemv(char trans, int m, int n, double alpha,
                const double *A, int lda, const double *X, int incX,
                double beta, double *Y, int incY) {
    dgemv_(&trans, &m, &n, &alpha, A, &lda, X, &incX, &beta, Y, &incY);
}