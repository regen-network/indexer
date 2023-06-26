FROM python:3.9

RUN apt-get update
RUN apt-get install libpq-dev postgresql-client -y

COPY . .

RUN pip install poetry
RUN pip install load_dotenv
RUN pip install psycopg2

RUN poetry install

COPY ./sql /home/indexer/migrations
COPY ./index.py /home/indexer/index.py
COPY ./docker/indexer_start.sh /home/indexer/start.sh
