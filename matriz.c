#include "matriz.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>  // Para uso de função 'memset()'

/**
 * Função que gera valores para para ser usado em uma matriz
 * @param i,j coordenadas do elemento a ser calculado (0<=i,j<n)
 *  @return valor gerado para a posição i,j
 */
static inline real_t generateRandomA(unsigned int i, unsigned int j) {
    static real_t invRandMax = 1.0 / (real_t)RAND_MAX;
    return ((i == j) ? (real_t)(BASE << 1) : 1.0) * (real_t)random() * invRandMax;
}

/**
 * Função que gera valores aleatórios para ser usado em um vetor
 * @return valor gerado
 *
 */
static inline real_t generateRandomB() {
    static real_t invRandMax = 1.0 / (real_t)RAND_MAX;
    return (real_t)(BASE << 2) * (real_t)random() * invRandMax;
}

/* ----------- FUNÇÕES ---------------- */

/**
 *  Funcao geraMatRow: gera matriz como vetor único, 'row-oriented'
 *
 *  @param m     número de linhas da matriz
 *  @param n     número de colunas da matriz
 *  @param zerar se 0, matriz  tem valores aleatórios, caso contrário,
 *               matriz tem valores todos nulos
 *  @return  ponteiro para a matriz gerada
 *
 */
MatRow geraMatRow(int m, int n, int zerar) {
    MatRow matriz = (real_t*)malloc(m * n * sizeof(real_t));

    if (matriz) {
        if (zerar)
            memset(matriz, 0, m * n * sizeof(real_t));
        else
            for (int i = 0; i < m; ++i)
                for (int j = 0; j < n; ++j)
                    matriz[i * n + j] = generateRandomA(i, j);
    }

    return (matriz);
}

/**
 *  Funcao geraVetor: gera vetor de tamanho 'n'
 *
 *  @param n  número de elementos do vetor
 *  @param zerar se 0, vetor  tem valores aleatórios, caso contrário,
 *               vetor tem valores todos nulos
 *  @return  ponteiro para vetor gerado
 *
 */
Vetor geraVetor(int n, int zerar) {
    Vetor vetor = (real_t*)malloc(n * sizeof(real_t));

    if (vetor) {
        if (zerar)
            memset(vetor, 0, n * sizeof(real_t));
        else
            for (int i = 0; i < n; ++i)
                vetor[i] = generateRandomB();
    }

    return (vetor);
}

/**
 *  \brief: libera vetor
 *
 *  @param  ponteiro para vetor
 *
 */
void liberaVetor(void* vet) {
    free(vet);
}

/**
 *  Funcao multMatVet:  Efetua multiplicacao entre matriz 'mxn' por vetor
 *                       de 'n' elementos
 *  @param mat matriz 'mxn'
 *  @param m número de linhas da matriz
 *  @param n número de colunas da matriz
 *  @param res vetor que guarda o resultado. Deve estar previamente alocado e com
 *             seus elementos inicializados em 0.0 (zero)
 *  @return vetor de 'm' elementos
 *
 */
void multMatVet(MatRow mat, Vetor v, int m, int n, Vetor res) {
    /* Efetua a multiplicação */
    if (res) {
        for (int i = 0; i < m; ++i)
            for (int j = 0; j < n; ++j)
                res[i] += mat[n * i + j] * v[j];
    }
}

/**
 *  Funcao multMatVetVetorizado:  Efetua multiplicacao entre matriz 'mxn' por vetor de 'n' elementos, com vetorização usando unroll & jam + blocking
 *  @param mat matriz 'mxn'
 *  @param m número de linhas da matriz
 *  @param n número de colunas da matriz
 *  @param res vetor que guarda o resultado. Deve estar previamente alocado e com
 *             seus elementos inicializados em 0.0 (zero)
 *  @return vetor de 'm' elementos
 *
 */
void multMatVetVetorizado(MatRow restrict mat, Vetor restrict v, int m, int n, Vetor restrict res) {
    /* Efetua a multiplicação */
    if (!res)
        return;

    // l para linha
    // c para coluna
    // k para posição do vetor
    int l_inicioBloco = 0, l_fimBloco = 0, c_inicioBloco = 0, c_fimBloco = 0;
	int linha_I0 = 0;
    // Se não, não cabe só na L1, é realizado o unroll & jam + blocking
    for (int iBloco = 0; iBloco < m / BLOCK_SIZE; iBloco++) {
        l_inicioBloco = BLOCK_SIZE * iBloco;
        l_fimBloco = BLOCK_SIZE + l_inicioBloco;

        for (int jBloco = 0; jBloco < n / BLOCK_SIZE; jBloco++) {
            c_inicioBloco = BLOCK_SIZE * jBloco;
            c_fimBloco = BLOCK_SIZE + c_inicioBloco;

            for (int i = l_inicioBloco; i < l_fimBloco; i += UNROLL) {
				// Para evitar recálculos, já que é (i + UNROLL) * n, executando apenas UMA multiplicação, ao invés de 4
				linha_I0 = (i * n);

				for (int j = c_inicioBloco; j < c_fimBloco; j++) {
                    res[i] += mat[linha_I0 + j] * v[j];
                    res[i + 1] += mat[linha_I0 + n + j] * v[j];
					res[i + 2] += mat[linha_I0 + n + n + j] * v[j];
                    res[i + 3] += mat[linha_I0 + n + n + n + j] * v[j];
                }
			}
        }
    }

    // Caso os blocos estejam divididos sem problemas.
    if (m % BLOCK_SIZE == 0)
        return;

    // Realiza para o resto abaixo, ou seja, a partir de m - m mod BLOCK_SIZE
    for (int i = m - (m % BLOCK_SIZE); i < m; i++) {
        // Executa para todas as colunas.
        for (int j = 0; j < n; j++) {
            res[i] += mat[(i * n) + j] * v[j];
        }
    }
    // Realiza para o resto a direita, ou seja, a partir de n - n mod BLOCK_SIZE
    for (int i = 0; i < n - (n % BLOCK_SIZE); i++) {
        // Executa para as colunas que estão apos os blocos.
        for (int j = n - (n % BLOCK_SIZE); j < n; j++) {
            res[i] += mat[(i * n) + j] * v[j];
        }
    }
}

/**
 *  Funcao multMatMat: Efetua multiplicacao de duas matrizes 'n x n'
 *  @param A matriz 'n x n'
 *  @param B matriz 'n x n'
 *  @param n ordem da matriz quadrada
 *  @param C   matriz que guarda o resultado. Deve ser previamente gerada com 'geraMatPtr()'
 *             e com seus elementos inicializados em 0.0 (zero)
 *
 */
void multMatMat(MatRow A, MatRow B, int n, MatRow C) {
    /* Efetua a multiplicação */
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            for (int k = 0; k < n; ++k)
                C[i * n + j] += A[i * n + k] * B[k * n + j];
}

/**
 *  Funcao multMatMatVetorizado:  Efetua multiplicacao entre matriz 'mxn' por outra matriz 'mxn', com vetorização usando unroll & jam + blocking
 *  @param A matriz 'n x n'
 *  @param B matriz 'n x n'
 *  @param n ordem da matriz quadrada
 *  @param C   matriz que guarda o resultado. Deve ser previamente gerada com 'geraMatPtr()'
 *             e com seus elementos inicializados em 0.0 (zero)
 *
 */
void multMatMatVetorizado(MatRow restrict A, MatRow restrict B, int n, MatRow restrict C) {
    int l_inicioBloco, l_fimBloco;
    int c_inicioBloco, c_fimBloco;
    int kstart, kend;
	int indice_A = 0, indice_B = 0, indice_C = 0;

    for (int iBloco = 0; iBloco < n / BLOCK_SIZE; ++iBloco) {
        l_inicioBloco = iBloco * BLOCK_SIZE;
        l_fimBloco = l_inicioBloco + BLOCK_SIZE;

        for (int jBloco = 0; jBloco < n / BLOCK_SIZE; ++jBloco) {
            c_inicioBloco = jBloco * BLOCK_SIZE;
            c_fimBloco = c_inicioBloco + BLOCK_SIZE;

            for (int kk = 0; kk < n / BLOCK_SIZE; ++kk) {
                kstart = kk * BLOCK_SIZE;
                kend = kstart + BLOCK_SIZE;

                for (int i = l_inicioBloco; i < l_fimBloco; ++i) {
					for(int j = c_inicioBloco; j < c_fimBloco; j += UNROLL) {
						// Para evitar recálculos, aproveitando o fato de que são loops aninhados
						indice_C =  i * n + j;

						for (int k = kstart; k < kend; ++k) {
							// Para evitar recálculos
							indice_A = (indice_C - j) + k;
							indice_B = (k * n) + j;
							C[indice_C + 0] += A[indice_A] * B[indice_B + 0];
							C[indice_C + 1] += A[indice_A] * B[indice_B + 1];
							C[indice_C + 2] += A[indice_A] * B[indice_B + 2];
							C[indice_C + 3] += A[indice_A] * B[indice_B + 3];
						}
					}
				}
            }
        }
    }

	// Caso não sobre nada, não tem o que fazer né?
    if (n % BLOCK_SIZE == 0)
        return;

	// Realiza para o resto
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            for (int k = 0; k < n; ++k)
                C[i * n + j] += A[i * n + k] * B[k * n + j];
}

/**
 *  Funcao prnMat:  Imprime o conteudo de uma matriz em stdout
 *  @param mat matriz
 *  @param m número de linhas da matriz
 *  @param n número de colunas da matriz
 *
 */
void prnMat(MatRow mat, int m, int n) {
    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < n; ++j)
            printf(DBL_FIELD, mat[n * i + j]);
        printf("\n");
    }
    printf(SEP_RES);
}

/**
 *  Funcao prnVetor:  Imprime o conteudo de vetor em stdout
 *  @param vet vetor com 'n' elementos
 *  @param n número de elementos do vetor
 *
 */
void prnVetor(Vetor vet, int n) {
    for (int i = 0; i < n; ++i)
        printf(DBL_FIELD, vet[i]);
    printf(SEP_RES);
}
