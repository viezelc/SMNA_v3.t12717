# Versão SMNA da branch SMNA_v3.0.0.t12717:  
https://svn.cptec.inpe.br/smna/branch/SMNA_v3.0.0.t12717

Versão instalada na Egeon, seguindo os passos abaixo:


1. Clone:
   ```
   cd ${HOME}
   svn co https://svn.cptec.inpe.br/smna/branch/SMNA_v3.0.0.t12717
    ```
2. Configuração do SMNA:
   ```
   cd SMNA_v3.0.0.t12717
   cd SMG/etc/mach
   ```
   Editar arquivo `egeon_paths.conf` e ajustar a variável "nome_smg" para ##SMNA_v3.0.0.t12717/SMG##

   Na sequência config:
   ```
   cd SMNA_v3.0.0.t12717/SMG
   ./config_smg.ksh configure
   ```

3. Ajuste para resolver problema na compilação (esse ajuste não subiu para o svn):
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/cptec/gsi/util/global_angupdate
   vi Makefile.conf.egeon-intel
   ```
   Comentei:
   ```
   #COREGSI  = /mnt/beegfs/$(USER_NAME)/SMNA_v3.0.0.t11889/SMG/cptec/gsi
   #CORELIB  = /mnt/beegfs/$(USER_NAME)/SMNA_v3.0.0.t11889/SMG/cptec/gsi/libsrc
   #CORECRTM = /mnt/beegfs/$(USER_NAME)/SMNA_v3.0.0.t11889/SMG/cptec/gsi/libsrc
   ```
   e add as linhas:
   ```
   COREGSI  = /home/$(USER_NAME)/SMNA_v3.0.0.t12717/SMG/cptec/gsi
   CORELIB  = /home/$(USER_NAME)/SMNA_v3.0.0.t12717/SMG/cptec/gsi/libsrc
   CORECRTM = /home/$(USER_NAME)/SMNA_v3.0.0.t12717/SMG/cptec/gsi/libsrc
   ```

4. Compilação do GSI e BAM:
   ```
   cd SMNA_v3.0.0.t12717/SMG
   nohup ./config_smg.ksh compile > compile1.log &
   ```

5. Testcase:
   ```
   cd SMNA_v3.0.0.t12717/SMG
   ./config_smg.ksh testcase
   ```
   Escolher opção [2].

6. Execução:
   
   AJUSTES NECESSÁRIOS:
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/cptec/bam/run
   ```
   copiar os arquivos `ruModel` e `EnvironmentalVariables_sapucci`:
   ```
   cp /home/caroline.viezel/SMNA_v3.0.0.t12717/SMG/cptec/bam/run/EnvironmentalVariables_sapucci
   cp /home/caroline.viezel/SMNA_v3.0.0.t12717/SMG/cptec/bam/run/runModel
   ```

   No runModel é preciso fazer source no `EnvironmentalVariables_sapucci` pois ao rodar o runModel com o source no `EnvironmentalVariables` dá erro!
   ```
   source /home/${USER}/SMNA_v3.0.0.t12717/SMG/cptec/bam/run/EnvironmentalVariables_sapucci
   ```
   Quando utilizei apenas o `EnvironmentalVariables_sapucci` o runPre dá erro devido algumas funcionalidades que o João inseriu (ex.: getMPIinfo) não estarem definidas nesse ambiente.
   Logo, utilizo os dois: `EnvironmentalVariables_sapucci` para o runModel e `EnvironmentalVariables` para o runPre.
   
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/cptec/bam/run
   ./runPre -t 299 -l 64 -I 2025050900 -n 0 -O -T -G -Gt Netcdf -s
   ```

   Verificar se vai baixar os dados corretos do teste: 2025050900  

   Se não, vai dar erro! os arquivos estão em:
   ```
   cd /mnt/beegfs/caroline.viezel/SMNA_v3.0.0.t12717/SMG/datainout/bam/pre/datain/
   cp /mnt/beegfs/luiz.sapucci/SMNA_v3.0.0.t11889/SMG/datainout/bam/pre/datain/*2025050900* .
   ```

   Rodar o Modelo:
   ```
   ./runModel -t 299 -l 64 -I 2025050900 -F 2025050909 -ts 3 -py SMT -px CPT -das
   ```

   CICLO DO SMNA  

   Antes modifica caminho das observações:
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/run/scripts/gsi_scripts
   vi runGSI_Functions.sh
   ```
   Editar o obsDir para ler o local: /oper/dados/dboper/raw/arch/mod/ncep/gdas/
   ```
   local obsDir=/oper/dados/dboper/raw/arch/mod/ncep/gdas/${runDate:0:4}/${runDate:4:2}/${runDate:6:2}
   ```
   
   RODAR:
   
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/run
   ./run_cycle.sh -t 299 -l 64 -gt 299 -p CPT -I 2025050906 -F 2025050912
   ```
