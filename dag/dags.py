from airflow import DAG
from airflow.operators import BashOperator
from datetime import datetime, timedelta

# Following are defaults which can be overridden later on
default_args = {
    'owner': 'cimentadaj',
    'depends_on_past': False,
    'start_date': datetime(2020, 11, 22),
    'email': ['cimentadaj@gmail.com'],
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(seconds=10)
}

dag = DAG('bicing-scraper', default_args=default_args)

t1 = BashOperator(
    task_id='grab-and-push',
    bash_command="Rscript '/usr/local/bicing_experiment/scrape_daily.R'",
    schedule_interval= '*/5 * * * *',
    dag=dag
)

t2 = BashOperator(
    task_id='Finished',
    bash_command='echo "Finished!"',
    dag=dag
)

t2.set_upstream(t1)
