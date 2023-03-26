FROM python:3.10-slim-buster

RUN apt-get update \
    && apt-get install -y --no-install-recommends

RUN mkdir app

WORKDIR /app

COPY nhl_dbt/ .

# Install the dbt Snowflake adapter. This step will also install dbt-core
RUN pip install --upgrade pip
RUN pip install dbt-snowflake==1.4.1

CMD dbt build --profiles-dir .