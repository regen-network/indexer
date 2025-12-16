FROM python:3.9

# Install dependencies
RUN apt-get update
RUN apt-get install libpq-dev postgresql-client nodejs python3-poetry yarnpkg -y

# Set working directory
WORKDIR /home/indexer

# Copy source code
COPY . .

# Install indexer
RUN poetry install --no-root
RUN yarnpkg install 
