# Versão SMNA da branch SVN ajustada no GitHub

Repositório de origem no SVN: SMNA_v3.0.0.t12717:  
https://svn.cptec.inpe.br/smna/branch/SMNA_v3.0.0.t12717

Versão instalada na Egeon, seguindo os passos abaixo:

0. Observe os pré requisitos antes de iniciar

   GitHub:  
   Pré-requisito: Git LFS  
   Caso não tenha instalado fazer --->  
   Linux (Ubuntu/Debian): `sudo apt install git-lfs`  
   macOS (Homebrew): `brew install git-lfs`  
   Windows: Baixar o instalador direto do site oficial.  
   ATIVAR: `git lfs install`

1. Clone a versão depois de atender os requisitos acima e faca o checkout do branch:
   
   ```
   cd ${HOME}
   git clone https://github.com/viezelc/SMNA_v3.t12717.git SMNA_v3.0.0.t12717
   cd SMNA_v3.0.0.t12717
   git checkout chore/ajustes-config
   ```

2. Depois do repositório clonado fazer o lfs pull (passo importante):
   ```
   git lfs pull
   ```
   
3. Configuração do SMNA:
   ```
   cd SMNA_v3.0.0.t12717/SMG
   ./config_smg.ksh configure
   ```
Obs. Caso tenha ou queira mais de uma versão edite arquivo `egeon_paths.conf` e ajustar a variável "nome_smg" para um outro nome desejado. A atual versão está como "SMNA_v3.0.0.t12717/SMG"

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

6. Execução do pré na rodada anterior para preparação do ciclo de assimilação:
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/cptec/bam/run
   ./runPre -t 299 -l 64 -I 2025050900 -n 0 -O -T -G -Gt Netcdf -s
   ```

   OBS. Verificar se os arquivos necessarios serão corretamente encontrados para essa data: 2025050900. Caso dê erro por falta de arquivos uma copia esta no diretorio abaixo.
   Copia para seu /mnt/beegfs/${USER}/SMNA_v3.0.0.t12717/SMG/datainout/bam/pre/datain/ 
   ```
   ls /mnt/beegfs/caroline.viezel/SMNA_v3.0.0.t12717/SMG/datainout/bam/pre/datain/
   ```
   
7. Rodar o Modelo para essa data anterior para preparar os FirstGuess do inicio do ciclo de assimilação:
   ```
   ./runModel -t 299 -l 64 -I 2025050900 -F 2025050909 -ts 3 -py SMT -px CPT -das -r
   ```

8. Testar do ciclo de assimilação no SMNA  
   ```
   cd ~/SMNA_v3.0.0.t12717/SMG/run
   ./run_cycle.sh -t 299 -l 64 -gt 299 -p CPT -I 2025050906 -F 2025050912
   ```
