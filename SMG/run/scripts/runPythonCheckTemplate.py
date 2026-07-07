#! /usr/bin/env python3
print(' ')
import gsidiag as gd
from datetime import datetime, timedelta
import pandas as pd
import matplotlib.pyplot as plt

DIRdiag="/mnt/beegfs/#USER#/SMNA_v3.0.0.t12717/SMG/datainout/gsi/dataout/"
dateIni="#YYYYMMDDHH#" 

print(' ')
try: 
    print('##### Lendo o arquivo do OMF: '+DIRdiag+dateIni+'/diag_conv_01.'+dateIni)
    fileOmF = gd.read_diag(DIRdiag+dateIni+'/diag_conv_01.'+dateIni)
    print('##### Lista das variaveis disponiveis no OMF (pfileinfo): ')
    fileOmF.pfileinfo()
    print(' ')
 
except:
    print('#Problema#: arquivo OMF dos convencionais nao encontrado ou com problema na leitura: ')
    print(DIRdiag+dateIni+'/diag_conv_01.'+dateIni)
    print(' ')

try: 
    print('##### Lendo o arquivo do OMA: '+DIRdiag+dateIni+'/diag_conv_03.'+dateIni)
    fileOmA = gd.read_diag(DIRdiag+dateIni+'/diag_conv_01.'+dateIni)
    print('##### Lista das variaveis disponiveis no OMA (pfileinfo): ')    
    fileOmA.pfileinfo()
except:
    print('#Problema#: arquivo OMA dos convencionais nao encontrado ou com problema na leitura: ')
    print(DIRdiag+dateIni+'/diag_conv_03.'+dateIni)
    print(' ')

  
print("")
print("----------------- Fim do teste do Python --------------------")

