# Versão SMNA da branch SVN ajustada no GitHub

Repositório de origem no SVN: SMNA_v3.0.0.t12717:  
https://svn.cptec.inpe.br/smna/branch/SMNA_v3.0.0.t12717

Essa versão instalada totalmente no beegfs da Egeon para ser utilizada na jaci via container. A estratégia do container é para facilitar ou contornar as dificuldades com a compilação na JACI. A ideia é compilar na EGEON e apenas rodar na JACI. Depois de compilado na EGEON um tar de todo o pacte será feito e destarjeado na JACI e executado lá. Para isso é preciso que toda a estruura deve estar no mesmo repositorio que é o BEEGFS da EGEON para que o pacote depois de destarjeado funcione no lustre da JACI. 

Para a compilação na egeon os seguindo os passos abaixo devem ser feito:

1. Observe os pré requisitos antes de iniciar

   GitHub:  
   Pré-requisito: Git LFS  
   Caso não tenha instalado fazer --->  
   Linux (Ubuntu/Debian): `sudo apt install git-lfs`  
   macOS (Homebrew): `brew install git-lfs`  
   Windows: Baixar o instalador direto do site oficial.  
   ATIVAR: `git lfs install`

2. Clone a versão depois de atender os requisitos acima:
 
   ```
   cd /mnt/beegfs/${USER};
   git clone https://github.com/viezelc/SMNA_v3.t12717.git SMNA_v3.0.0.beegfs;
   cd SMNA_v3.0.0.beegfs;
   ```

3. Caso seo caso faca o checkout em um branch desejado, caso queira usar o master pule essa etapa:
   
   ```
   git checkout SMNA_v3.0.0_beegfs;
   ```

4. Depois do repositório clonado fazer o lfs pull (passo importante):
   ```
   git lfs pull
   ```
   
5. Configuração do SMNA:
   ```
   cd /mnt/beegfs/${USER}/SMNA_v3.0.0.beegfs/SMG;
   ./config_smg.ksh configure
   ```
**Obs1.** Caso tenha ou queira mais de uma versão edite arquivo `egeon_paths.conf` e ajustar a variável "nome_smg" para um outro nome desejado. A atual versão está como "SMNA_v3.0.0.t12717/SMG"

**Obs2.:** caso a cópia do repositório não esteja em `/home/${USER}`, ajuste os caminhos das flags: COREGSI, CORELIB e CORECRTM no arquivo `Makefile.conf.egeon-intel` em `SMNA_v3.0.0.t12717/SMG/cptec/gsi/util/global_angupdate/`.

6. Compilação do GSI e BAM:
   ```
   cd /mnt/beegfs/${USER}/SMNA_v3.0.0.beegfs/SMG;
   nohup ./config_smg.ksh compile > compile1.log &
   ```

7. Testcase:
   ```
   cd /mnt/beegfs/${USER}/SMNA_v3.0.0.beegfs/SMG;
   ./config_smg.ksh testcase
   ```
   Escolher opção [2].

8. Execução do pré na rodada anterior para preparação do ciclo de assimilação:
   ```
   cd /mnt/beegfs/${USER}/SMNA_v3.0.0.beegfs/SMG/cptec/bam/run;
   ./runPre -t 299 -l 64 -I 2025050900 -n 0 -O -T -G -Gt Netcdf -s
   ```

   OBS. Verificar se os arquivos necessarios serão corretamente encontrados para essa data: 2025050900. Caso dê erro por falta de arquivos uma copia esta no diretorio abaixo.
   Copia para seu /mnt/beegfs/${USER}/SMNA_v3.0.0.t12717/SMG/datainout/bam/pre/datain/ 
   ```
   ls /mnt/beegfs/caroline.viezel/SMNA_v3.0.0.t12717/SMG/datainout/bam/pre/datain/
   ```
   
9. Rodar o Modelo para essa data anterior para preparar os FirstGuess do inicio do ciclo de assimilação:
   ```
   ./runModel -t 299 -l 64 -I 2025050900 -F 2025050909 -ts 3 -py SMT -px CPT -das -r
   ```

10. Testar o ciclo de assimilação no SMNA  
   ```
   cd /mnt/beegfs/${USER}/SMNA_v3.0.0.beegfs/SMG/run;
   ./run_cycle.sh -t 299 -l 64 -gt 299 -p CPT -I 2025050906 -F 2025050912
   ```

11. ☑️ Arquivos de saída:
    
    ARQUIVOS setout modelo ->  
    modelo: /mnt/beegfs/${USER}/SMNA_v3.0.0.t12717/SMG/datainout/bam/model/DAS
    
    ARQUIVOS datarun GSI ->  
    GSI: /mnt/beegfs/${USER}/SMNA_v3.0.0.t12717/SMG/datarun/gsi
    
    RESULTADOS ->  
    Saídas do GSI: /mnt/beegfs/${USER}/SMNA_v3.0.0.t12717/SMG/datainout/gsi/dataout  
    Saídas do modelo: /mnt/beegfs/${USER}/SMNA_v3.0.0.t12717/SMG/datainout/bam/model/dataout/TQ0299L064/DAS

12. Pós-processamento das previsões (rodar o Pós):  
    Obs.: verificar se o arquivo `POSTIN-GRIB.template` encontra-se no diretório `SMG/cptec/bam/run`. Este arquivo foi adicionado recentemente e pode ser encontrado em https://projetos.cptec.inpe.br/projects/smna/repository/revisions/162/entry/branch/SMNA_v3.0.x/SMG/cptec/bam/run/POSTIN-GRIB.template

   ↪️ Exemplo para previsão de 5 dias: ⬇️
   ```
   cd /mnt/beegfs/${USER}/SMNA_v3.0.0.beegfs/SMG/cptec/bam/run
   ```
Previsões:
   ``` 
   ./runModel -t 299 -l 64 -I 2025050906 -F 2025051406 -ts 6 -py CPT -px CPT
   ```
Pós:
   ```  
   ./runPos -t 299 -l 64 -I 2025050906 -F 2025051406
   ```
