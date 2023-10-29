#!/usr/bin/gnuplot -c
## set encoding iso_8859_15
set encoding utf
set terminal qt persist
set grid
set style data point
set style function line
set style line 1 lc 3 pt 7 ps 0.3
set boxwidth 1
set xtics
set xrange ["0":]
set xlabel  "Tamanho do vetor"

#
# Tabelas em arquivos separados (2 colunas)
#

# Definindo qual é o eixo Y
campo = ARG2
set ylabel campo
set logscale y

# Definindo qual será a métrica que será plotada
metrica = ARG1

# Define o nome do arquivo .dat
mat_vet_otimizado = sprintf("./%s/plot-%s-%s-MatVet.dat", "dados_grafico", "Otimizado", metrica)
mat_vet_nao_otimizado = sprintf("./%s/plot-%s-MatVet.dat", "dados_grafico", metrica)
mat_mat_otimizado = sprintf("./%s/plot-%s-MatMat.dat", "dados_grafico", metrica)
mat_mat_nao_otimizado = sprintf("./%s/plot-%s-MatMat.dat", "dados_grafico", metrica)


# Define o título do gráfico
titulo = metrica


if(metrica ne "FLOPS_DP"){
     # Definindo o estilo dos pontos
     set linetype 1 lw 2 dashtype 2 lc rgb "dark-grey" # Algortmo não otimizado (cinza pontilhado)
     set linetype 2 lw 2 lc rgb "dark-green" # Algortmo otimizado (verde escuro)

     # Plot dos dados
     set terminal qt 1 title "Métrica <" . metrica . ">[matriz * vetor]"
     plot   mat_vet_nao_otimizado title "(mat-vet sem otimização)" with lines lt 1, \
            mat_vet_otimizado title "(com otimização)" with lines lt 2
     pause -1
} else{
     # Definindo os estilos de linha e cores
     set linetype 1 lw 2  dashtype 2 lc rgb "brown"  # Série não otimizada (marrom tracejado)
     set linetype 2 lw 2  dashtype 2 lc rgb "dark-grey" # Série não otimizada (cinza tracejado)
     set linetype 3 lw 2 lc rgb "dark-blue"  # Série otimizada (azul)
     set linetype 4 lw 2 lc rgb "dark-green" # Série otimizada (verde)

     #Plot dos dados
     set terminal qt 1 title "Métrica <" . metrica . ">[matriz * vetor]"
     plot mat_vet_nao_otimizado using 1:2 title "Cálculos DP (sem otimização)" with linespoints lt 1, \
     mat_vet_nao_otimizado using 1:3 title "Cálculos DP vetorizados (sem otimização)" with linespoints lt 2, \
     mat_vet_otimizado using 1:2 title "Cálculos DP (com otimização)" with linespoints lt 3, \
     mat_vet_otimizado using 1:3 title "Cálculos DP vetorizados (com otimização)" with linespoints lt 4
     mat_mat_nao_otimizado using 1:2 title "Seu terceiro conjunto de dados" with linespoints lt 5, \
     mat_mat_nao_otimizado using 1:2 title "Seu terceiro conjunto de dados" with linespoints lt 5, \
     mat_mat_otimizado using 1:2 title "Seu quarto conjunto de dados" with linespoints lt 6
     mat_mat_otimizado using 1:2 title "Seu quarto conjunto de dados" with linespoints lt 6
     pause -1
}