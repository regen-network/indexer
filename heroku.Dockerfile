FROM python:3.9

# Install dependencies
RUN apt-get update
RUN apt-get install curl libpq-dev postgresql-client nodejs yarnpkg -y

# Set working directory
WORKDIR /home/indexer

# Copy source code
COPY . .

# Install indexer and pin the version of poetry
RUN pip3 install poetry==1.6.1
RUN poetry install
# the heroku.yml 'run' directive is incompatible with poetry
# so we export to the requirements.txt format and use pip3 
RUN poetry export --without-hashes --format=requirements.txt > requirements.txt
RUN pip3 install -r requirements.txt 
RUN yarnpkg install
