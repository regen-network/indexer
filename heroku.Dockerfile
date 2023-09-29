FROM python:3.9

# Install dependencies
RUN apt-get update
RUN apt-get install curl libpq-dev postgresql-client nodejs yarnpkg -y

# Set working directory
WORKDIR /home/indexer

# Copy source code
COPY . .

# Install indexer
RUN pip3 install poetry==1.6.1
RUN poetry install
RUN poetry export --without-hashes --format=requirements.txt > requirements.txt
RUN pip3 install -r requirements.txt 
RUN yarnpkg install
