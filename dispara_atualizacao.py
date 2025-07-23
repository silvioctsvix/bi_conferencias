import logging
import traceback
import obter_data_atualizacao as od
from apscheduler.schedulers.blocking import BlockingScheduler

logging.basicConfig(
    filename='log_atualizacao_bi.log', 
    level=logging.INFO, 
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)

def job_atualizacao():
    """Função wrapper para executar a atualização com tratamento de erros adequado"""
    try:
        logging.info("Iniciando execução do job de atualização")
        od.obter_data()
        logging.info("Job de atualização concluído com sucesso")
    except Exception as e:
        logging.error(f"Erro na execução do job de atualização: {str(e)}")
        logging.error(traceback.format_exc())
        # Continuar a execução mesmo com erro

# Criar o scheduler
scheduler = BlockingScheduler()

# Adicionar o job com a função wrapper
scheduler.add_job(job_atualizacao, 'cron', hour='6, 9, 11, 13, 15, 17, 19, 21', minute=10)

# Iniciar o scheduler com tratamento de exceções
try:
    logging.info("Iniciando o scheduler")
    scheduler.start()
except (KeyboardInterrupt, SystemExit):
    logging.info("Scheduler interrompido pelo usuário")
    scheduler.shutdown()
except Exception as e:
    logging.error(f"Erro ao executar o scheduler: {str(e)}")
    logging.error(traceback.format_exc())
    scheduler.shutdown()
