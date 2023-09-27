FROM python:3.9

# Install dependencies
RUN apt-get update
RUN apt-get install libpq-dev postgresql-client -y

# Set working directory
WORKDIR /home/indexer

# Copy source code
COPY . .

# Install python dependencies
RUN pip install poetry
RUN pip install load_dotenv
RUN pip install psycopg2
RUN pip install sentry_sdk
RUN pip install tenacity

# Install indexer
RUN poetry install
