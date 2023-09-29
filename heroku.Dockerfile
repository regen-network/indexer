FROM python:3.9

# Install dependencies
RUN apt-get update
RUN apt-get install curl libpq-dev postgresql-client nodejs python3-poetry yarnpkg -y

# Set working directory
WORKDIR /home/indexer

# Copy source code
COPY . .

# Install indexer
RUN poetry install
RUN poetry export --without-hashes --format=requirements.txt > requirements.txt
RUN pip3 install -r requirements.txt 
RUN yarnpkg install
