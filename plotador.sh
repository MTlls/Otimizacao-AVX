#!/bin/bash

declare -A metricas

# Defina as métricas e campos correspondentes
metricas=()
metricas["FLOPS_DP"]="Cálculos de Dupla Precisão (MFLOP/s)"
metricas["ENERGY"]="Energia (Joule)"
metricas["L2CACHE"]="Taxa de misses na cache L2"
metricas["L3"]="Banda da cache L3 (MBytes/s)"
metricas["TEMPO"]="Tempo em milisegundos"

# Loop que pega cada campo e sua chave e o coloca como argumento, que ajudam no plotMetrica.gp a produzir um gráfico mais informações
for metrica in "${!metricas[@]}"
do
    campo="${metricas[$metrica]}"
    gnuplot -geometry -800-600 -c plotMetrica.gp "${metrica}" "${campo}"
done