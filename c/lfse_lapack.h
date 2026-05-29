/* lfse_lapack.h
 * Thin C shim exposing selected LAPACK routines for the Lean LSMC implementation.
 * Column-major storage (Fortran/LAPACK convention).
 * Return codes: 0 on success; LAPACK info code otherwise.
 * See spec §13.4 and T-005.
 */
#ifndef LFSE_LAPACK_H
#define LFSE_LAPACK_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Solves A*X = B for SPD A (Cholesky, dposv).
 * A is n x n (column-major), B is n x nrhs (overwritten with X on success).
 * Returns 0 on success, >0 if the leading minor of order i is not positive definite.
 */
int lfse_dposv(int n, int nrhs, double *A, double *B);

/* Solves min ||A*X - B|| in least-squares sense (dgels, QR or LQ).
 * A is m x n (column-major), B is max(m,n) x nrhs (overwritten).
 * Returns 0 on success.
 */
int lfse_dgels(int m, int n, int nrhs, double *A, double *B);

/* Matrix-vector multiply: Y := alpha*A*X + beta*Y (dgemv).
 * Used for beta · phi prediction after OLS solve.
 */
void lfse_dgemv(char trans, int m, int n, double alpha,
                const double *A, int lda, const double *X, int incX,
                double beta, double *Y, int incY);

#ifdef __cplusplus
}
#endif

#endif /* LFSE_LAPACK_H */