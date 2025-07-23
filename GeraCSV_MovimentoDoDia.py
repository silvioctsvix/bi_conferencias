#!/usr/bin/env python
# coding: utf-8

# Este módulo gera os arquivos CSV da movimentaçao de processos abertos e Conferências para alimentar a base de dados do BI de Conferências
# 
# Os bancos de dados dbDetranNet e SIT_COPIA são READONLY, neste caso é necessário incluir no script de conexão o parámeetro ApplicationIntent com o valor "ReadOnly"

# In[6]:


import pyodbc
import pandas as pd
import warnings
import os
import re
from dotenv import load_dotenv
#import csv
warnings.filterwarnings('ignore')

# Carregar variáveis de ambiente do arquivo .env, se existir
load_dotenv()

#variáveis de trabalho
datai                           = '27/08/2023'
dataf                           = '27/08/2023'
#diretorio_destino_processos     = 'C:\\Temp'
#diretorio_destino_conferencias  = 'C:\\Temp'
diretorio_destino_processos     = 'D:\\Silvio\OneDrive\Trabalho\POWER BI\AUDITORIA PROCESSO SS DIGITAL - NEW\DB-Procesoss Abertos'
diretorio_destino_conferencias  = 'D:\\Silvio\OneDrive\Trabalho\POWER BI\AUDITORIA PROCESSO SS DIGITAL - NEW\DB'
#arquivo_destino_processos       = '/Processos_'
#arquivo_destino_conferencias    = '/AuditoriasProcessosDigitais_'
arquivo_script_sql_Processos    = 'SQL Processos Abertos Atualizado Original.sql'
arquivo_script_sql_Conferencias = 'SQL Auditoria Processos Digitais Original.sql'
caracter_separador              = '|'

#10.4.2.51
#10.243.129.234
def conecta_ao_banco(
    driver=None,
    server=None,
    database=None,
    username=None,
    password=None,
    ApplicationIntent=None
):
    driver = driver or os.environ.get("DB_DRIVER", "ODBC Driver 17 for SQL Server")
    server = server or os.environ.get("DB_SERVER")
    database = database or os.environ.get("DB_DATABASE")
    username = username or os.environ.get("DB_USERNAME")
    password = password or os.environ.get("DB_PASSWORD")
    ApplicationIntent = ApplicationIntent or os.environ.get("DB_APPLICATION_INTENT", "ReadOnly")

    string_conexao = (
        f"DRIVER={driver};SERVER={server};DATABASE={database};"
        f"UID={username};PWD={password};APPLICATIONINTENT={ApplicationIntent}"
    )
    conexao = pyodbc.connect(string_conexao)
    return conexao

def manter_imprimiveis(texto):
    return ''.join(re.findall(r'[\x20-\x7E]', str(texto)))

def apaga_arquivo_incremental(arquivo):
    if os.path.exists(arquivo):
        try:
            os.remove(arquivo)
            return True
        except OSError as erro:
            return False
    else:
        return True

def GeraCSVMovimentoDia(data_movimento, tipo_movimento):
    datai = data_movimento
    dataf = data_movimento

    try:
        conexao = conecta_ao_banco()
    except Exception as erro:
        return "Erro ao conectar com o banco de dados: " + str(erro)

    if tipo_movimento == 'incremental':
        arquivo_destino_processos    = '/_Processos_'+data_movimento.replace("/", "")+'_'+tipo_movimento+'.csv'
        arquivo_destino_conferencias = '/_AuditoriasProcessosDigitais_'+data_movimento.replace("/", "")+'_'+tipo_movimento+'.csv'
    else:
        arquivo_destino_processos    = '/_Processos_'+data_movimento.replace("/", "")+'.csv'
        arquivo_destino_conferencias = '/_AuditoriasProcessosDigitais_'+data_movimento.replace("/", "")+'.csv'

    #apara arquivo incremental do dia 
    if apaga_arquivo_incremental(diretorio_destino_processos+arquivo_destino_processos) == False:
        return "Erro ao apagar arquivo de processos incremental!"
    #apara arquivo incremental do dia anterior
    if apaga_arquivo_incremental(diretorio_destino_processos+arquivo_destino_processos.replace(".csv", "_incremental.csv")) == False:
        return "Erro ao apagar arquivo de processos incremental!"

    try:
        #%%time
        #Le o arquivo com o comando SQL dos Processos
        with open(arquivo_script_sql_Processos, 'r') as file:
            query = file.read()
        df_teste = pd.read_sql(query, conexao, params=(datai, dataf))
        if df_teste.empty == False:
            df_teste.to_csv(diretorio_destino_processos+arquivo_destino_processos, sep=caracter_separador, index=False, encoding='utf-8')
            
    except Exception as erro:
        return "Erro ao gerar o arquivo CSV com os processos abertos no dia: " + str(erro)

    #apara arquivo incremental do dia 
    if apaga_arquivo_incremental(diretorio_destino_conferencias+arquivo_destino_conferencias) == False:
        return "Erro ao apagar arquivo de conferência incremental!"
    #apara arquivo incremental do dia anterior
    if apaga_arquivo_incremental(diretorio_destino_conferencias+arquivo_destino_conferencias.replace(".csv", "_incremental.csv")) == False:
        return "Erro ao apagar arquivo de conferência incremental!"

    try:
        #%%time
        #Le o arquivo com o comando SQL das Conferências
        with open(arquivo_script_sql_Conferencias, 'r') as file:
            query = file.read()
        df_teste = pd.read_sql(query, conexao, params=(datai, dataf))
        if df_teste.empty == False:
            df_teste.to_csv(diretorio_destino_conferencias+arquivo_destino_conferencias, sep=caracter_separador, index=False, encoding='utf-8')
        
    except Exception as erro:
        return "Erro ao gerar o arquivo CSV com as conferências feitas no dia: " + str(erro)

    try:
        conexao.close()
    except Exception as erro:
        return "Erro ao desconectar do banco de dados: " + str(erro)
    
    
