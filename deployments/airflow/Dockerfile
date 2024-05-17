ARG BASE_IMAGE=apache/airflow:2.7.1-python3.10
FROM $BASE_IMAGE

USER airflow
RUN pip install --upgrade pip

RUN pip install apache-airflow[amazon,celery,snowflake]==2.7.1 --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.7.1/constraints-3.10.txt"

COPY requirements-airflow.txt /tmp/requirements-airflow.txt
RUN pip install --no-cache-dir -r /tmp/requirements-airflow.txt

COPY requirements-dev.txt /tmp/requirements-dev.txt
RUN pip install --no-cache-dir -r /tmp/requirements-dev.txt
