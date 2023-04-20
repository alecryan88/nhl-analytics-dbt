FROM python:3.10-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends

RUN mkdir app

WORKDIR /app

COPY nhl_dbt/ .

COPY dbt.sh . 

# Make dbt.sh an executable
RUN chmod +x dbt.sh

RUN pip install awscli --upgrade

#Install the dbt Snowflake adapter. This step will also install dbt-core
#Install boto3 for copying files out to s3
RUN pip install --upgrade pip
RUN pip install dbt-snowflake==1.4.1
RUN pip install boto3

#Ensure all dependenices are installed
RUN dbt deps

CMD ["sh", "dbt.sh"]