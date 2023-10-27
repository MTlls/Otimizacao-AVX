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
static void usage(char *progname) {
	fprintf(stderr, "Forma de uso: %s [ <ordem> ] \n", progname);
	exit(1);
}

/**
 * Programa principal
 * Forma de uso: matmult [ -n <ordem> ]
 * -n <ordem>: ordem da matriz quadrada e dos vetores
 *
 */
int main(int argc, char *argv[]) {
	int n = DEF_SIZE;
	rtime_t tempo = 0;
	MatRow mRow_1, mRow_2, resMat;
	Vetor vet, res;

	/* =============== TRATAMENTO DE LINHA DE COMANDO =============== */

	if(argc < 2)
		usage(argv[0]);

	n = atoi(argv[1]);

	/* ================ FIM DO TRATAMENTO DE LINHA DE COMANDO ========= */

	srandom(20232);
	

	res = geraVetor(n, 1);  // (real_t *) malloc (n*sizeof(real_t));
	resMat = geraMatRow(n, n, 1);

	mRow_1 = geraMatRow(n, n, 0);
	mRow_2 = geraMatRow(n, n, 0);

	vet = geraVetor(n, 0);

	if(!res || !resMat || !mRow_1 || !mRow_2 || !vet) {
		fprintf(stderr, "Falha em alocação de memória !!\n");
		liberaVetor((void *)mRow_1);
		liberaVetor((void *)mRow_2);
		liberaVetor((void *)resMat);
		liberaVetor((void *)vet);
		liberaVetor((void *)res);
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

#ifndef _O_
    // Marcador matriz X vetor (sem otimização)
    LIKWID_MARKER_START("MAT_VET");
	tempo = timestamp();
	multMatVet(mRow_1, vet, n, n, res);
	tempo = timestamp() - tempo;
    LIKWID_MARKER_STOP("MAT_VET");
#else
    // Marcador matriz X vetor (com otimização)
    LIKWID_MARKER_START("MAT_VET");
	tempo = timestamp();
	multMatVetVetorizado(mRow_1, vet, n, n, res);
	tempo = timestamp() - tempo;
    LIKWID_MARKER_STOP("MAT_VET");
#endif /* Caso queira otimizar */

// Apenas para comparar os resultados
#ifdef _DEBUG_
	prnVetor(res, n);
#endif /* _DEBUG_ */

	// Print para o GNUPLOT
	fprintf(stdout, "TAMANHO: %d\nTempo médio: %lf\n", n, tempo);

    // Marcador matriz X matriz
    LIKWID_MARKER_START("MAT_MAT");
	// multMatMat(mRow_1, mRow_2, n, resMat);
    LIKWID_MARKER_STOP("MAT_MAT");

    // Fecha o marcador.
    LIKWID_MARKER_CLOSE;

#ifdef _DEBUG_
	prnVetor(res, n);
	prnMat(resMat, n, n);
#endif /* _DEBUG_ */

	liberaVetor((void *)mRow_1);
	liberaVetor((void *)mRow_2);
	liberaVetor((void *)resMat);
	liberaVetor((void *)vet);
	liberaVetor((void *)res);

	return 0;
}
