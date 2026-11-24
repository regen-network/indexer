FROM python:3.9

# Install dependencies
RUN apt-get update
RUN apt-get install curl libpq-dev postgresql-client nodejs yarnpkg -y

# Set working directory
WORKDIR /home/indexer

# Copy source code
COPY . .

# The heroku.yml 'run' directive is incompatible with poetry, so poetry is only
# used to export the locked dependencies to the requirements.txt format, which
# pip3 then installs. Poetry (pinned) runs from its own virtualenv: installed
# next to the indexer, its unpinned dependencies (e.g. a newer
# charset-normalizer) were later replaced by the locked versions, leaving
# files of both versions behind and breaking `import requests`.
RUN python -m venv /opt/poetry \
  && /opt/poetry/bin/pip install --no-cache-dir poetry==1.6.1 \
  && /opt/poetry/bin/poetry export --without-hashes --format=requirements.txt > requirements.txt
RUN pip3 install --no-cache-dir -r requirements.txt
RUN yarnpkg install
