FROM python:3.9

RUN apt-get update
RUN apt-get install libpq-dev postgresql-client -y

COPY . .

RUN pip install poetry
RUN pip install load_dotenv
RUN pip install psycopg2
RUN pip install sentry_sdk
RUN pip install tenacity

RUN poetry install

COPY ./sql /home/indexer/sql

COPY ./index_blocks.py /home/indexer/index_blocks.py
COPY ./index_proposals.py /home/indexer/index_proposals.py
COPY ./index_retires.py /home/indexer/index_retires.py
COPY ./main.py /home/indexer/main.py
COPY ./utils.py /home/indexer/utils.py

COPY ./docker/indexer_start.sh /home/indexer/start.sh
