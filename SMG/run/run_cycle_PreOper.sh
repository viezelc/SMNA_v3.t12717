#!/bin/bash
#-----------------------------------------------------------------------------#
#           Group on Data Assimilation Development - GDAD/CPTEC/INPE          #
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT: script utilizado para realizar os ciclos de assimilação de dados
#
# !DESCRIPTION:
#
# !CALLING SEQUENCE:
#
#   ./run_cycle.sh <opções>
#
#      As <opções> válidas são
#          * -t   <val> : truncamento das previsões do BAM [default: XX]
#          * -l   <val> : número de níveis [default: XX]
#          * -gt  <val> : truncamento das condições iniciais do BAM [default: XX]
#          * -p   <val> : prefixo dos arquivos do BAM (condição inicial e previsões) [default: CPT]
#          * -I   <val> : Data da primeira condição inicial do ciclo
#          * -F   <val> : Data da útima condição inicial do ciclo
#          * -bc  <val> : Número de ciclo da correção de viés do satélite [default: 0]
#          * -bcI <val> : Data inicial do primeiro ciclo de correção de viés do satélite
#          * -bcF <val> : Data final do último ciclo de correção de viés do satélite
#          * -h   <val> : Mostra este help
#
#          exemplo:
#          ./run_cycle.sh -t 62 -l 28 -gt 62 -p CPT -I 2015043006 -F 2015043006 -gt 62 -bc 10 -bcI 2015043006 -bcF 2015043006
#
# !REVISION HISTORY:
# 05 Set 2018 - J. G. de Mattos - Initial Version
# 28 Nov 2023 - Aravequia, J. A. - Changing the use of "inctime"  for `date ` Linux command 
# !REMARKS:
#
#EOP
#-----------------------------------------------------------------------------#
#BOC

#-----------------------------------------------------------------------------#
# Carregando as variaveis do sistema
cd ..

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
RootDir="$(dirname "$SCRIPT_PATH")"
export SMG_ROOT=${RootDir}
source ${SMG_ROOT}/config_smg.ksh vars_export

cd run

subwrd() {
   str=$(echo "${@}" | awk '{ for (i=1; i<=NF-1; i++) printf("%s ",$i)}')
   n=$(echo "${@}" | awk '{ print $NF }')
   echo "${str}" | awk -v var=${n} '{print $var}'
}

#-----------------------------------------------------------------------------#
# return usage from main program
#-----------------------------------------------------------------------------#
usage() {
   echo
   echo "Usage:"
   sed -n '/^#BOP/,/^#EOP/{/^#BOP/d;/^#EOP/d;p}' ${BASH_SOURCE}
}

modelMPITasks=64  # Number of Processors used by model
modelFCT=09        # Time length of model forecasts
gsiMPITasks=144    # Number of Processors used by gsi

do_obsmake=0
do_gsi=1 
do_bam=1

i=1
flag=0
while true; do

   arg=$(echo "${@}" | awk -v var=${i} '{print $var}')
   i=$((i+1))

   if [ -z ${arg} ]; then break; fi

   while true; do
      # model options
      if [ ${arg} = '-t' ]; then modelTrunc=$(subwrd ${@} ${i}); i=$((i+1));  break; fi
      if [ ${arg} = '-l' ]; then modelNLevs=$(subwrd ${@} ${i}); i=$((i+1));  break; fi
      if [ ${arg} = '-p' ]; then modelPrefix=$(subwrd ${@} ${i}); i=$((i+1)); break; fi

      if [ ${arg} = '-mnp' ]; then modelMPITasks=$(subwrd ${@} ${i}); i=$((i+1)); break; fi

      # general options
      if [ ${arg} = '-I' ];   then LABELI=$(subwrd ${@} ${i}); i=$((i+1));   break; fi
      if [ ${arg} = '-F' ];   then LABELF=$(subwrd ${@} ${i}); i=$((i+1));   break; fi
      if [ ${arg} = '-fct' ]; then modelFCT=$(subwrd ${@} ${i}); i=$((i+1)); break; fi

      # gsi options
      if [ ${arg} = '-gt' ];  then gsiTrunc=$(subwrd ${@} ${i}); i=$((i+1)); break; fi
      if [ ${arg} = '-bc' ];  then BcCycles=$(subwrd ${@} ${i}); i=$((i+1)); break; fi
      if [ ${arg} = '-bcI' ]; then BcLABELI=$(subwrd ${@} ${i}); i=$((i+1)); break; fi
      if [ ${arg} = '-bcF' ]; then BcLABELF=$(subwrd ${@} ${i}); i=$((i+1)); break; fi

      if [ ${arg} = '-gnp' ]; then gsiMPITasks=$(subwrd ${@} ${i}); i=$((i+1)); break; fi

      if [ ${arg} = '-h' ]; then cat < ${0} | sed -n '/^#BOP/,/^#EOP/p' ; i=$((i+0)); exit 0; fi

      flag=1
      i=$((i-1))

      break
   done

   if [ ${flag} -eq 1 ]; then break; fi

done

# Truncamento do background
if [ -z ${modelTrunc} ]; then
   echo -e "\e[31;1m >> Erro: \e[m\e[33;1m Truncamento do modelo não foi passado\e[m"
   usage
   exit -1
fi

# Numero de niveis do background
if [ -z ${modelNLevs} ]; then
   echo -e "\e[31;1m >> Erro: \e[m\e[33;1m Número de níveis do modelo não foi passado\e[m"
   usage
   exit -1
fi

# Prefixo do arquivo de background
if [ -z ${modelPrefix} ]; then
   echo -e "\e[31;1m >> Erro: \e[m\e[33;1m Prefixo dos arquivos do modelo não foi passado\e[m"
   usage
   exit -1
fi

# Data inicial da rodada
if [ -z ${LABELI} ]; then
   echo -e "\e[31;1m >> Erro: \e[m\e[33;1m A data inicial não foi passada\e[m"
   usage
   exit -1
fi

# Data final da rodada
if [ -z ${LABELF} ]; then
   echo -e "\e[31;1m >> Erro: \e[m\e[33;1m A data Final não foi passada\e[m"
   usage
   exit -1
fi

# Truncamento em que a análise será calculada
# Obs: Este é o mesmo truncamento utilizado no
#      cálculo prévio da matriz de covariância
#      do erro. Então esta será a resolução em
#      que o GSI irá processar internamente a
#      análise. Pode ser diferente do Truncamento
#      do modelo.
if [ -z ${gsiTrunc} ]; then
   gsiTrunc=${modelTrunc}
fi

modelMRES=$(printf 'TQ%4.4dL%3.3d' ${modelTrunc} ${modelNLevs})
gsiMRES=$(printf 'TQ%4.4dL%3.3d' ${gsiTrunc} ${gsiNLevs})

# Não haverá modificações na coordenada vertical
export gsiNLevs=${modelNLevs}

echo -e ""
echo -e "\033[34;1m CONFIGURACAO DA RODADA \033[m"
echo -e ""
echo -e "\033[34;1m > Resolucao do Modelo : \033[m \033[31;1m${modelMRES}\033[m"
echo -e "\033[34;1m > Resolucao do GSI    : \033[m \033[31;1m${modelMRES}\033[m"
echo -e "\033[34;1m > Data Inicial        : \033[m \033[31;1m${LABELI}\033[m"
echo -e "\033[34;1m > Data Final          : \033[m \033[31;1m${LABELF}\033[m"
echo -e "\033[34;1m > Tempo de Previsao   : \033[m \033[31;1m${modelFCT}\033[m"

# OPCAO PARA CORRECAO DE VIES DO ANGULO DO SATELITE
#
# Verificar se foi chamada alguma variável de bc do gsi
# se for chamada, as outras devem estar consistentes
# e então deve-se realizar o BC antes das simulação padrão
if  [ ! -z ${BcLABELI} ] || [ ! -z ${BcLABELF} ] || [ ! -z ${BcCycles} ]; then

   if [ -z ${BcLABELI} ]; then
      echo -e "\e[31;1m >> Erro: \e[m\e[33;1m A data inicial para o periodo de Correcao de Vies não foi passado\e[m"
      usage
      exit -1
   fi

   if [ -z ${BcLABELF} ]; then
      echo -e "\e[31;1m >> Erro: \e[m\e[33;1m A data final para o periodo de Correcao de Vies não foi passado\e[m"
      usage
      exit -1
   fi

   if [ -z ${BcCycles} ]; then
      echo -e "\e[31;1m >> Erro: \e[m\e[33;1m O numero de ciclos para Correcao de Vies não foi passado\e[m"
      usage
      exit -1
   fi

   echo -e ""
   echo -e "\033[34;1m CORRECAO DE VIES DO SATELITE ACIONADA \033[m"
   echo -e ""
   echo -e "\033[34;1m > Data Inicial      : \033[m \033[31;1m${BcLABELI}\033[m"
   echo -e "\033[34;1m > Data Final        : \033[m \033[31;1m${BcLABELF}\033[m"
   echo -e "\033[34;1m > Numero de Ciclos  : \033[m \033[31;1m${BcCycles}\033[m"

   while [ ${BcLABELI} -le ${BcLABELF} ]; do
      cd ${run_smg}

      echo ""
      echo -e "\033[34;1m >>> Submetendo o Sistema ${nome_smg} para o dia \033[31;1m${BcLABELI}\033[m \033[m"
      echo ""

      echo -e "\033[34;1m > Executando o Observer \033[m"
      SECONDS=0

#      if [ ${do_obsmake} -eq 1 ] ; then
#        # Prepara as obsevacoes para a assimilacao no GSI utilizando um background do MCGA
#        echo /bin/bash ${scripts_smg}/run_obsmake.sh ${BcLABELI}
#        /bin/bash ${scripts_smg}/run_obsmake.sh ${BcLABELI}
#        if [ $? -ne 0 ]; then 
#           echo -e "\033[31;1m > Falha no Observer \033[m"
#           exit 1
#        fi
#
#        echo ""
#        duration=$SECONDS
#        echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
#        echo -e "\033[34;1m > Fim do Observer \033[m"
#      fi  

      echo ""
      echo -e "\033[34;1m > Executando o GSI \033[m"

      if [ ${do_gsi} -eq 1 ] ; then
         # Executa o GSI
         SECONDS=0
         echo /bin/bash ${scripts_smg}/runGSI -t ${modelTrunc} -T ${gsiTrunc} -l ${modelNLevs} -p ${modelPrefix} -np ${gsiMPITasks} -I ${BcLABELI} -bc ${BcCycles}
         /bin/bash ${scripts_smg}/runGSI -t ${modelTrunc} -T ${gsiTrunc} -l ${modelNLevs} -p ${modelPrefix} -np ${gsiMPITasks} -I ${BcLABELI} -bc ${BcCycles}
         if [ $? -ne 0 ]; then 
            echo -e "\033[31;1m > Falha no GSI \033[m" 
            exit 1
         fi

         echo ""
         duration=$SECONDS
         echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
         echo -e "\033[34;1m > Fim do GSI \033[m"
      fi

      if [ ${do_bam} -eq 1 ]; then
         # Executa o MCGA com as analises do GSI
         SECONDS=0

         ### FCT_DATE=$(${inctime} ${BcLABELI} +${modelFCT}h %y4%m2%d2%h2)
         ## using built in Linux command to increment the date
         FCT_DATE=`date -u +%Y%m%d%H -d "${BcLABELI:0:8} ${BcLABELI:8:2} +${modelFCT} hours" `


         echo ""
         echo -e "\033[34;1m > Executando o MCGA \033[m"
                                                                                                                               ##  Pos-Proc (Yes/No)
         echo "/bin/bash ${scripts_smg}/run_model.sh ${BcLABELI} ${FCT_DATE} ${modelPrefix} ${modelTrunc} ${modelNLevs} ${modelMPITasks} No"
         /bin/bash ${scripts_smg}/run_model.sh ${BcLABELI} ${FCT_DATE} ${modelPrefix} ${modelTrunc} ${modelNLevs} ${modelMPITasks} No
         if [ $? -ne 0 ]; then echo -e "\033[31;1m > Falha no MCGA \033[m"; exit 1; fi

         echo ""
         duration=$SECONDS
         echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
         echo -e "\033[34;1m > Fim do MCGA \033[m"
      fi
      ### BcLABELI=$(${inctime} ${BcLABELI} +6h %y4%m2%d2%h2)
      BcLABELI=`date -u +%Y%m%d%H -d "${BcLABELI:0:8} ${BcLABELI:8:2} +6 hours" `

   done

   ### LABELI=$(${inctime} ${BcLABELF} +6h %y4%m2%d2%h2)
   LABELI=`date -u +%Y%m%d%H -d "${BcLABELF:0:8} ${BcLABELF:8:2} +6 hours" `
fi

GSIok=0
ContNotOk=0
stSMNA=/pesq/share/das/dist/luiz.sapucci/SMNAfluxCPT/runningStatus.log
Psok=1
radioOK=1
CODIerroGSI=0

while [ ${LABELI} -le ${LABELF} ]; do
   cd ${run_smg}
   
   echo ""
   echo -e "\033[34;1m >>> Submetendo o Sistema ${nome_smg} para o dia \033[31;1m${LABELI}\033[m \033[m"
   echo ""

   if [ ${do_obsmake} -eq 1 ] ; then
     echo -e "\033[34;1m > Executando o Observer \033[m"
     SECONDS=0
  
     # Prepara as obsevacoes para a assimilacao no GSI utilizando um background do MCGA
     echo /bin/bash ${scripts_smg}/run_obsmake.sh ${LABELI}
     /bin/bash ${scripts_smg}/run_obsmake.sh ${LABELI}
     if [ $? -ne 0 ]; then 
        echo -e "\033[31;1m > Falha no Observer \033[m"
        exit 1
     fi
  
     echo ""
     duration=$SECONDS
     echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
     echo -e "\033[34;1m > Fim do Observer \033[m"
   fi

   if [ ${do_gsi} -eq 1 ] ; then
     echo ""
     echo -e "\033[34;1m > Executando o GSI \033[m"

      # Executa o GSI
     SECONDS=0
     /bin/bash ${scripts_smg}/runGSI -t ${modelTrunc} -T ${gsiTrunc} -l ${modelNLevs} -p ${modelPrefix} -np ${gsiMPITasks} -I ${LABELI}
     if [ $? -ne 0 ]; then 
       echo -e "\033[31;1m > Falha no GSI: Codigo de erro: $? \033[m"
#        exit 1 
       CODIerroGSI=$?
       echo "data:" 
       date
       GSIok=0
     else
       CODIerroGSI=0
       GSIok=1
       echo ""
       duration=$SECONDS
       echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
       echo -e "\033[34;1m > Fim do GSI \033[m"
     fi
   fi
#   # Executa o BLSDAS
#   echo ""
#   echo -e "\033[34;1m > Executando o BLSDAS \033[m"
#
#   SECONDS=0
#   /bin/bash ${scripts_smg}/run_blsdas.sh -t ${modelTrunc} -l ${modelNLevs} -p ${modelPrefix} -d ${LABELI}
#   if [ $? -ne 0 ]; then echo -e "\033[31;1m > Falha no BLSDAS \033[m"; exit 1; fi
#
#   echo ""
#   duration=$SECONDS
#   echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
#   echo -e "\033[34;1m > Fim do GSI \033[m"

# Testando se os dados convencionais do CPTEC foram assimilados corretamente
   if [ ${GSIok} -eq 1 ] ; then  
     echo "Testando os dados convencionais do CPTEC se ok: " $LABELI

     sed "s/#USER#/${USER}/g" ${scripts_smg}/runPythonCheckTemplate.py |  sed "s/#YYYYMMDDHH#/${LABELI}/g"  > runPythonCheck.py
     chmod 755 ./runPythonCheck.py
   
     source /home/caroline.viezel/.conda/envs/readDiagGerd/bin/activate
     ./runPythonCheck.py &> runPythonCheck.log
   
     proble=`grep "#Problema#" runPythonCheck.log | wc -l`
     lognLin=`more runPythonCheck.log | wc -l`
     logPs=`grep "Variable Name : ps" runPythonCheck.log | wc -l`
     logRADI0=`grep "kx => 120" runPythonCheck.log | wc -l`   
   
     if [ ${proble} -ne 0 ]; then 
       echo ">>>>>>> Problemas nos dados covencionais CPTEC....";
       echo ">>>>>>> Problemas nos dados covencionais CPTEC...." > DaigConv.log 
       cat runPythonCheck.log;
       GSIok=0 ;
     else
#       if [ ${lognLin} -ne 36 ]; then ##### Modifique esse numero de linhas atualizando os dados assimilados
       if [ ${logPs} -ne 2 ]; then
         echo -e "\033[31;1m >>>>>>> Verificar dados assimilados. Valores de press�o inexistente...\033[m"; 
	 echo  ">>>>>>> Verificar dados assimilados. Valores de press�o inexistente..." >> DaigConv.log
         cat runPythonCheck.log;
         Psok=0	 
       else
         if [ ${logRADI0} -ne 6 ]; then
           echo -e "\033[31;1m >>>>>>> Verificar dados assimilados. Valores de radiossondas inexistente...\033[m";
	   echo ">>>>>>> Verificar dados assimilados. Valores de radiossondas inexistente..." >> DaigConv.log
	   echo  
           cat runPythonCheck.log;
         #GSIok=0
           radioOK=0
         else
           echo "########"
           echo "## ok!!!";
           echo "########"
	   echo "## ok!!!" > DaigConv.log	   
         fi 
       fi
     fi 
   fi   
     
# ROdando o Bam dentro do ciclo de assimila��o  

   if [ ${do_bam} -eq 1 ] && [ ${GSIok} -eq 1 ]; then
      # Executa o MCGA com as analises do GSI
      SECONDS=0
      ### FCT_DATE=$(${inctime} ${LABELI} +${modelFCT}h %y4%m2%d2%h2)
      FCT_DATE=`date -u +%Y%m%d%H -d "${LABELI:0:8} ${LABELI:8:2} +${modelFCT} hours" `
      echo ""
      echo -e "\033[34;1m > Executando o MCGA \033[m"
      echo  "/bin/bash ${scripts_smg}/run_model.sh ${LABELI} ${FCT_DATE} ${modelPrefix} ${modelTrunc} ${modelNLevs} ${modelMPITasks} No"
      /bin/bash ${scripts_smg}/run_model.sh ${LABELI} ${FCT_DATE} ${modelPrefix} ${modelTrunc} ${modelNLevs} ${modelMPITasks} No
      if [ $? -ne 0 ]; then  
        echo -e "\033[31;1m > Falha no modelo :\033[m \033[33;1mVerifique PRE, BAM ou POS\033[m";
	#exit 1; 
	echo "Mudando o gsiOk para 0 para rodar novamente"
	echo "data:" 
        date
	GSIok=0
      fi
      
      echo ""
      duration=$SECONDS
      echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
      echo -e "\033[34;1m > Fim do MCGA \033[m"
   fi

   if [ ${GSIok} -eq 1 ] ; then
   
     echo "&&& " $LABELI $Psok $radioOK  ${ContNotOk}
    
     echo "Log de status da rodada operacional do SMNA com o fluxo de dados do cptec" > ${stSMNA}
     echo "Rodada das "$LABELI  >> ${stSMNA}
     echo "!!!!!!!!!!!!!!!!!!!!!!" >> ${stSMNA}
     echo "Status:     OK " >> ${stSMNA}
     echo "!!!!!!!!!!!!!!!!!!!!!!" >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo "Dados salvos em https://ftp1.cptec.inpe.br/pesquisa/das/luiz.sapucci/SMNAfluxCPT/gsi_dataout/"${LABELI}  >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo "Diagnsotico da base de dados convencionais usada"  >> ${stSMNA}
     more DaigConv.log >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo "--------------------" >> ${stSMNA}
     more runPythonCheck.log >> ${stSMNA}
	 
     echo -e "\033[34;1m > Salvando dados do GSI no FTP fora da EGEON: \033[m"      
     cp -R /mnt/beegfs/luiz.sapucci/SMNA_v3.0.0.t12717/SMG/datainout/gsi/dataout/${LABELI} /pesq/share/das/dist/luiz.sapucci/SMNAfluxCPT/gsi_dataout/

     ### LABELI=$(${inctime} ${LABELI} +6h %y4%m2%d2%h2)
     LABELI=`date -u +%Y%m%d%H -d "${LABELI:0:8} ${LABELI:8:2} +6 hours" ` 
     GSIok=0
     ContNotOk=0
     Psok=1
     radioOK=1
     
   else
     # Caso n�o tenha dados no processo em tempo real ele fica esperando 30 minutos antes de resubmeter a mesma data
     echo -e "\033[34;1m > Aguardando dados disponiveis: \033[m" 
     ContNotOk=$((ContNotOk+1))
     echo "30 min"
     sleep 600
     echo "20 min"
     sleep 600
     echo "10 min"
     sleep 540
     echo "1 min" ${ContNotOk}
     sleep 60
   
   fi

   if [ ${CODIerroGSI} -ne 0 ] ; then
     echo ""
     echo "#################################################################################"   
     echo "Processo interropido por problemas na rodada anterior do cilo de assimila��o"
     echo "Enviando aviso para os responsaveis providenciar rodar novamente o passo anterior "
     echo "#################################################################################"  
     echo "Log de status da rodada operacional do SMNA com o fluxo de dados do cptec" > ${stSMNA}
     echo "Rodada das "$LABELI  >> ${stSMNA}
     echo "!!!!!!!!!!!!!!!!!!!!!!" >> ${stSMNA}
     echo "Status:    INTERROPIDO " >> ${stSMNA}
     echo "!!!!!!!!!!!!!!!!!!!!!!" >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo " Acionar equipe de assimila��o para reiniciar o processo na data anterior.... "  >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo "#############################################################################"  >> ${stSMNA} 
     echo "Processo interropido por problemas na rodada anterior do cilo de assimila��o" >> ${stSMNA}
     echo "Enviando aviso para os responsaveis providenciar a rodada do passo anterior ">> ${stSMNA}
     echo "#############################################################################"  >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo " Motivo:. "  >> ${stSMNA}          
     echo "codigo de erro do GSI: Exit "${CODIerroGSI}
     if [ ${CODIerroGSI} -eq 2 ] ; then echo ">>>>> Falta dados do fisrt guess da rodada anterior,"  >> ${stSMNA}; fi
     if [ ${CODIerroGSI} -eq 3 ] ; then echo ">>>>> Executavel do GSI n�o encontrado,"  >> ${stSMNA}; fi
     if [ ${CODIerroGSI} -eq 4 ] ; then echo ">>>>> Coeficientes de BC da rodada anterior n�o encontrado."  >> ${stSMNA}; fi
     exit 0
              
   fi

   if [ ${ContNotOk} -gt 11 ] ; then
     echo ""
     echo "######################################################################"   
     echo "Enviando aviso para os responsaveis providenciar os dados disponiveis"
     echo "Tempo de espera: "  $((ContNotOk*30)) "Minutos"
     echo "Que e maior que a janela de 6h dados usada"
     echo "######################################################################"  

     echo "Log de status da rodada operacional do SMNA com o fluxo de dados do cptec" > ${stSMNA}
     echo "Rodada das "$LABELI  >> ${stSMNA}
     echo "!!!!!!!!!!!!!!!!!!!!!!" >> ${stSMNA}
     echo "Status:     ATRASADO " >> ${stSMNA}
     echo "!!!!!!!!!!!!!!!!!!!!!!" >> ${stSMNA}
     echo "" >> ${stSMNA}
     echo "     Tempo de espera: "  $((ContNotOk*30)) "Minutos" >> ${stSMNA}
     echo "Que e maior que a janela de 6h dados usada" >> ${stSMNA}
     echo " Acionar equipe de dados no pre do CPTEC.... "  >> ${stSMNA}
     
   fi
   
done

#EOC
#-----------------------------------------------------------------------------#
