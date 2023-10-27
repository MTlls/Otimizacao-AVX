#!/bin/bash
METRICA="FLOPS_DP ENERGY L2CACHE MEM"
CPU=3

LIKWID_HOME=/home/soft/likwid
CFLAGS="-I${LIKWID_HOME}/include -DLIKWID_PERFMON"

PROGRAM="./matmult"
MAKEFILE="make"
PURGE="purge"

TAMANHOS=(0 64, 100, 128, 200, 256, 512, 600, 900)

# É um vetor chave-valor associativo, para capturar os campos sem muito código, não foi feito para DP FLOPS e AVX FLOPS pois é diferente o processo para captura-lo
declare -A metricas

if [ "$1" = "-O" ]; then
    OTIMIZA="Otimizado-"  # Armazena o valor atual de $1 em OTIMIZA
    TIPO="(com otimização)" # Coluna do .dat terá o seguinte nome
else
    OTIMIZA=""  # Define OTIMIZA como vazio
    TIPO="(sem otimização)" # Coluna do .dat terá o seguinte nome
fi

# começa a escrever para a metrica de tempo
echo "# Marcador \"matRowVet\" <TEMPO>" > "plot-${OTIMIZA}TEMPO-MatVet.dat"
echo "# n TEMPO_MEDIO $TIPO">> "plot-${OTIMIZA}TEMPO-MatVet.dat"

for k in $METRICA
do
    ARQUIVO_PLOT="plot-${OTIMIZA}${k}-MatVet.dat"
    # Coloca nos arquivos .dat o "cabeçalho" deles
    echo "# Marcador \"matRowVet\" <$k>" > ${ARQUIVO_PLOT}

    # o modo de produção do cabeçalhos é diferente para dp_flops
    if [ "$k" == "FLOPS_DP" ]; then
        echo "# n FLOPS_DP AVX FLOPS_AVX $TIPO" >> ${ARQUIVO_PLOT}
    else
        echo "# n <$k> $TIPO" >> ${ARQUIVO_PLOT}
    fi
    

    # Cada teste deve ser executado para os seguintes tamanhos de matriz:  N={64, 100, 128, 200, 256, 512, 600, 900, 1024, 2000, 2048, 3000, 4000};        
    for n in "${TAMANHOS[@]}"
        do
        # Adicione os parâmetros chave-valor
        case $k in
            ENERGY)
            metricas["$k"]="Energy \[J\]";;
            MEM)
            metricas["$k"]="Memory bandwidth \[MBytes/s\]";;
            L2CACHE)
            metricas["$k"]="L2 miss ratio";;
            *)
        esac
        
        # Execução do código com a métrica
        ./perfctr $1 ${CPU} ${k} ${PROGRAM} ${n}
        
        if [ "$k" == "FLOPS_DP" ]; then
            # Extrai o campo DP MFLOP/s e AVX DP MFLOPS/s dos logs do grupo FLOPS_DP
            # Para o marcador (MAT_VET)
            flops=$(awk "/Region MAT_VET, Group 1: ${k}/,/Region MAT_MAT, Group 1: FLOPS_DP/" ${k}_${n}.log | grep -E 'DP \[?MFLOP/s\]?' | sed 's/ //g' | cut -d '|' -f 3)

            # Extrai os respectivos campos
            dp=$(echo "$flops" | sed -n '1p')
            avx=$(echo "$flops" | sed -n '2p')

            echo "METRICA [$k]: " "$dp"
            echo "METRICA [AVX $k]: " "$avx"

            # escreve no .dat para futura plotagem
            echo "$n ${dp} ${avx}" >> ${ARQUIVO_PLOT}
        else
            # Para o marcador (MAT_VET)
            metricas["$k"]=$(awk "/Region MAT_VET, Group 1: ${k}/,/Region MAT_MAT, Group 1: ${k}/" ${k}_${n}.log | grep -E "${metricas[$k]}" | sed 's/ //g' | cut -d '|' -f 3)
            
            echo "METRICA [$k]: " ${metricas[$k]}

            # escreve no .dat para futura plotagem
            echo "$n ${metricas[$k]}" >> ${ARQUIVO_PLOT}
        fi
    done
done


for n in "${TAMANHOS[@]}"
do
    captura_tempo "$n"
done

captura_tempo(){
    ARQUIVO_FLOPS=FLOPS_DP_$1.log
    ARQUIVO_PLOT="plot-${OTIMIZA}TEMPO-MatVet.dat"
    
    # Criação do .dat de tempo precisa que seja feito para cada tamanho
    # Utilizado o FLOPS_DP.log como fonte mas podia ser o ENERGY.log
    # codigo é o conteudo do código...
    codigo=$(sed '1,/^-*$/d' ${ARQUIVO_FLOPS} | awk '/^-+$/ {exit} {print}')
    
    # Use cut para separar os campos usando ":"
    tamanho=$(grep "TAMANHO" ${ARQUIVO_FLOPS} | cut -d ':' -f 2 | tr -d ' ')
    tempo=$(grep "Tempo médio" ${ARQUIVO_FLOPS} | cut -d ':' -f 2 | tr -d ' ')

    echo "${tamanho} ${tempo} " >> ${ARQUIVO_PLOT}
}