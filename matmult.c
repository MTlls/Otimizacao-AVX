#include <getopt.h> /* getopt */
#include <stdio.h>
#include <stdlib.h> /* exit, malloc, calloc, etc. */
#include <string.h>
#include <time.h>

#include "likwid.h"
#include "matriz.h"
#include "utils.h"

/**
 * Exibe mensagem de erro indicando forma de uso do programa e termina
 * o programa.
 */
static void usage(char* progname) {
    fprintf(stderr, "Forma de uso: %s [ <ordem> ] \n", progname);
    exit(1);
}

/**
 * Programa principal
 * Forma de uso: matmult [ -n <ordem> ]
 * -n <ordem>: ordem da matriz quadrada e dos vetores
 *
 */
int main(int argc, char* argv[]) {
    int n = DEF_SIZE;
    rtime_t tempo = 0;
    MatRow mRow_1, mRow_2, resMat;
    Vetor vet, res;

    /* =============== TRATAMENTO DE LINHA DE COMANDO =============== */

    if (argc < 2)
        usage(argv[0]);

    n = atoi(argv[1]);

    /* ================ FIM DO TRATAMENTO DE LINHA DE COMANDO ========= */

    srandom(20232);

    res = geraVetor(n, 1);  // (real_t *) malloc (n*sizeof(real_t));
    resMat = geraMatRow(n, n, 1);

    mRow_1 = geraMatRow(n, n, 0);
    mRow_2 = geraMatRow(n, n, 0);

    vet = geraVetor(n, 0);

    if (!res || !resMat || !mRow_1 || !mRow_2 || !vet) {
        fprintf(stderr, "Falha em alocação de memória !!\n");
        liberaVetor((void*)mRow_1);
        liberaVetor((void*)mRow_2);
        liberaVetor((void*)resMat);
        liberaVetor((void*)vet);
        liberaVetor((void*)res);
        exit(2);
    }

#ifdef _DEBUG_
    prnMat(mRow_1, n, n);
    prnMat(mRow_2, n, n);
    prnVetor(vet, n);
    printf("=================================\n\n");
#endif /* _DEBUG_ */

    // Inicializa o marcador do likwid
    LIKWID_MARKER_INIT;

    // Marcador matriz X vetor (sem otimização)
    LIKWID_MARKER_START("MAT_VET");
    tempo = timestamp();

#ifndef _O_
    multMatVet(mRow_1, vet, n, n, res);
#else
    multMatVetVetorizado(mRow_1, vet, n, n, res);
#endif /* Caso queira otimizar */

    tempo = timestamp() - tempo;
    LIKWID_MARKER_STOP("MAT_VET");

    // Print para o GNUPLOT
    fprintf(stdout, "TAMANHO: %d\n mat_vet Tempo médio: %lf\n", n, tempo);

    // Marcador matriz X matriz
    LIKWID_MARKER_START("MAT_MAT");
    tempo = timestamp();
    
#ifndef _O_
    multMatMat(mRow_1, mRow_2, n, resMat);
#else
    mulMatMatOtim(mRow_1, mRow_2, n, resMat);
#endif

    tempo = timestamp() - tempo;
    LIKWID_MARKER_STOP("MAT_MAT");

    // Print para o GNUPLOT
    fprintf(stdout, "TAMANHO: %d\n mat_mat Tempo médio: %lf\n", n, tempo);

    // Fecha o marcador.
    LIKWID_MARKER_CLOSE;

#ifdef _DEBUG_
    // use um ou outro
    prnVetor(res, n);
    prnMat(resMat, n, n);
#endif /* _DEBUG_ */

    liberaVetor((void*)mRow_1);
    liberaVetor((void*)mRow_2);
    liberaVetor((void*)resMat);
    liberaVetor((void*)vet);
    liberaVetor((void*)res);

    return 0;
}
