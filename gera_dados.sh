#!/bin/bash
METRICA="FLOPS_DP ENERGY L2CACHE L3"
CPU=3

LIKWID_HOME=/home/soft/likwid
CFLAGS="-I${LIKWID_HOME}/include -DLIKWID_PERFMON"

PROGRAM="./matmult"
MAKEFILE="make"
PURGE="purge"
DAT_DIR="./dados_grafico/"
LOGS_DIR="./logs/"

TAMANHOS=(0 64 100 128 200 256 512 600 900 1024 2000 2048 3000 4000)

# É um vetor chave-valor associativo, para capturar os campos sem muito código,
# não foi feito para DP FLOPS e AVX FLOPS pois é diferente o processo para captura-lo
declare -A metricas

if [ "$1" = "-O" ]; then
    OTIMIZA="Otimizado-"
    OTIMIZAFLAG="-D_O_"  # Armazena o valor atual de $1 em OTIMIZA
    TIPO="(com otimização)" # Coluna do .dat terá o seguinte nome
else
    OTIMIZA=""  # Define OTIMIZA como vazio
    OTIMIZAFLAG=""
    TIPO="(sem otimização)" # Coluna do .dat terá o seguinte nome
fi

# começa a escrever para a metrica de tempo
echo "# Marcador \"matVet\" <TEMPO>" > "${DAT_DIR}plot-${OTIMIZA}TEMPO-MatVet.dat"
echo "# n TEMPO_MEDIO $TIPO" >> "${DAT_DIR}plot-${OTIMIZA}TEMPO-MatVet.dat"

echo "# Marcador \"matMat\" <TEMPO>" > "${DAT_DIR}plot-${OTIMIZA}TEMPO-MatMat.dat"
echo "# n TEMPO_MEDIO $TIPO" >> "${DAT_DIR}plot-${OTIMIZA}TEMPO-MatMat.dat"


make purge CFLAGS="${CFLAGS} ${OTIMIZAFLAG}" matmult 

for k in $METRICA
do
    # Definição do nome arquivo que será plotado.
    ARQUIVO_PLOT="${DAT_DIR}plot-${OTIMIZA}${k}-MatVet.dat"
    ARQUIVO_PLOT_MAT="${DAT_DIR}plot-${OTIMIZA}${k}-MatMat.dat"

    # Coloca nos arquivos .dat o "cabeçalho" deles
    echo "# Marcador \"matVet\" <$k>" > ${ARQUIVO_PLOT}
    echo "# Marcador \"matMat\" <$k>" > ${ARQUIVO_PLOT_MAT}

    # o modo de produção do cabeçalhos é diferente para dp_flops
    if [ "$k" == "FLOPS_DP" ]; then
        echo "# n FLOPS_DP AVX FLOPS_AVX $TIPO" >> ${ARQUIVO_PLOT}
        echo "# n FLOPS_DP AVX FLOPS_AVX $TIPO" >> ${ARQUIVO_PLOT_MAT}
    else
        echo "# n <$k> $TIPO" >> ${ARQUIVO_PLOT}
        echo "# n <$k> $TIPO" >> ${ARQUIVO_PLOT_MAT}
    fi

    # Cada teste deve ser executado para os seguintes tamanhos de matriz:  
    # N={64, 100, 128, 200, 256, 512, 600, 900, 1024, 2000, 2048, 3000, 4000};        
    for n in "${TAMANHOS[@]}"
    do
        ARQ_LOGS="${LOGS_DIR}${k}_${n}.log"
        # Adicione os parâmetros chave-valor
        case $k in
            ENERGY)
            metricas["$k"]="Energy \[J\]";;
            L3)
            metricas["$k"]="L3 bandwidth \[MBytes/s\]";;
            L2CACHE)
            metricas["$k"]="L2 miss ratio";;
            *)
        esac
        
        # Execução do código com a métrica
        ./perfctr ${CPU} ${k} ${PROGRAM} ${n}
        
        # Informações para acompanhar a execução
        echo
        echo "[${k}] Calculando para tamanho" "${n}"

        if [ "$k" == "FLOPS_DP" ]; then
            # Extrai o campo DP MFLOP/s e AVX DP MFLOPS/s dos logs do grupo FLOPS_DP
            flops=$(awk "/Region MAT_VET, Group 1: ${k}/,/Region MAT_MAT, Group 1: FLOPS_DP/" ${ARQ_LOGS} | grep -E 'DP \[?MFLOP/s\]?' | sed 's/ //g' | cut -d '|' -f 3)
            flops_mat=$(awk "/Region MAT_MAT, Group 1: ${k}/,/Region MAT_VET, Group 1: FLOPS_DP/" ${ARQ_LOGS} | grep -E 'DP \[?MFLOP/s\]?' | sed 's/ //g' | cut -d '|' -f 3)

            # Extrai os respectivos campos
            dp=$(echo "$flops" | sed -n '1p')
            avx=$(echo "$flops" | sed -n '2p')

            dp_mat=$(echo "$flops_mat" | sed -n '1p')
            avx_mat=$(echo "$flops_mat" | sed -n '2p')

            # pro terminal
            echo "[$k (MFLOP/s)]:" "$dp"
            echo "[AVX $k (MFLOP/s)]:" "$avx"

            echo "[$k (MFLOP/s)]:" "$dp_mat"
            echo "[AVX $k (MFLOP/s)]:" "$avx_mat"

            # escreve no .dat para futura plotagem
            echo "$n ${dp} ${avx}" >> ${ARQUIVO_PLOT}
            echo "$n ${dp_mat} ${avx_mat}" >> ${ARQUIVO_PLOT_MAT}
        else
            campo=${metricas[$k]}
            metricas["$k"]=$(awk "/Region MAT_VET, Group 1: ${k}/,/Region MAT_MAT, Group 1: ${k}/" ${ARQ_LOGS} | grep -E "${campo}" | sed 's/ //g' | cut -d '|' -f 3)

            # dependendo do campo ele terá umas '/' mas é esperado
            # devido ao formato de log produzido pelo likwid para cada arquitetura
            echo "[${campo}]: " ${metricas[$k]}

            # escreve no .dat para futura plotagem
            echo "$n ${metricas[$k]}" >> ${ARQUIVO_PLOT}
            
            metricas["$k"]=$(awk "/Region MAT_MAT, Group 1: ${k}/,/Region MAT_VET, Group 1: ${k}/" ${ARQ_LOGS} | grep -E "${campo}" | sed 's/ //g' | cut -d '|' -f 3)
            echo "[${campo}]: " ${metricas[$k]}

            # escreve no .dat para futura plotagem
            echo "$n ${metricas[$k]}" >> ${ARQUIVO_PLOT_MAT}
            
        fi
    done
done

captura_tempo(){
    ARQUIVO_FLOPS="${LOGS_DIR}FLOPS_DP_$1.log"
    ARQUIVO_PLOT="${DAT_DIR}plot-${OTIMIZA}TEMPO-MatVet.dat"
    ARQUIVO_PLOT_MAT="${DAT_DIR}plot-${OTIMIZA}TEMPO-MatMat.dat"
    
    # Criação do .dat de tempo precisa que seja feito para cada tamanho
    # Utiliza o FLOPS_DP.log como fonte, mas podia ser o ENERGY.log
    
    # Usa cut para separar os campos usando ":"
    tamanho=$(grep -m 1 "TAMANHO" ${ARQUIVO_FLOPS} | cut -d ':' -f 2 | tr -d ' ')
    tempo=$(grep "mat_vet Tempo médio" ${ARQUIVO_FLOPS} | cut -d ':' -f 2 | tr -d ' ')

    echo "${tamanho} ${tempo}" >> ${ARQUIVO_PLOT}

    tempo=$(grep "mat_mat Tempo médio" ${ARQUIVO_FLOPS} | cut -d ':' -f 2 | tr -d ' ')
    echo "${tamanho} ${tempo}" >> ${ARQUIVO_PLOT_MAT}
}

for n in "${TAMANHOS[@]}"
do
    captura_tempo "$n"
done