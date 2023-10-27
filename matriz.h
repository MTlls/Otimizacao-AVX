/* Constantes */

#define DBL_FIELD "%15.10lg"
#define SEP_RES "\n\n\n"

#define DEF_SIZE 128
#define BASE 32

#define ABS(num) ((num) < 0.0 ? -(num) : (num))

// Usamos o line cache size como 64 bytes (8 doubles)
#define BLOCK_SIZE 8

/* Tipos para matrizes e vetores */

typedef double real_t;

typedef real_t *MatRow;
typedef real_t *Vetor;

/* ----------- FUNÇÕES ---------------- */

MatRow geraMatRow(int m, int n, int zerar);
Vetor geraVetor(int n, int zerar);

void liberaVetor(void *vet);
void zeraVetor(Vetor vet, int n);

void multMatVet(MatRow mat, Vetor v, int m, int n, Vetor res);
void multMatVetVetorizado(MatRow restrict mat, Vetor restrict v, int m, int n, Vetor restrict res);
void multMatMat(MatRow A, MatRow B, int n, MatRow C);

void prnMat(MatRow mat, int m, int n);
void prnVetor(Vetor vet, int n);
