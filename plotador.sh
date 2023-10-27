#!/bin/bash

declare -A metricas

# Defina as métricas e campos correspondentes
metricas=()
metricas["FLOPS_DP"]="FLOPS_DP"
metricas["ENERGY"]="Energy [J]"
metricas["L2CACHE"]="L2 miss ratio"
metricas["MEM"]="Memory bandwidth [MBytes/s]"
metricas["TEMPO"]="Milisegundos [ms]"

# Loop que pega cada campo e sua chave e o coloca como argumento, que ajudam no plotMetrica.gp a produzir um gráfico mais informações
for metrica in "${!metricas[@]}"
do
    campo="${metricas[$metrica]}"
    gnuplot -c plotMetrica.gp "${metrica}" "${campo}"
done