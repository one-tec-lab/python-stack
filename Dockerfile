FROM python:3.7
#FROM ubuntu:18.04
#RUN apt-get update && apt-get install -y  python3 python3-pip libmysqlclient-dev python3-dev iputils-ping
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
COPY ./code/requirements.txt /code/
COPY wait-for.sh /code/
COPY ./code/ /code/
RUN pip3 install -r requirements.txt
#RUN apt-get clean && rm -rf /var/lib/apt/lists/*