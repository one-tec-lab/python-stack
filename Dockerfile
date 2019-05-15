FROM python:3.7
#FROM ubuntu:18.04
#RUN apt-get update && apt-get install -y  python3 python3-pip libmysqlclient-dev python3-dev iputils-ping

ENV PYTHONUNBUFFERED 1
RUN mkdir /workspace
WORKDIR /workspace
RUN pip3 install --upgrade pip
COPY ./app/ /workspace/
COPY ./app/requirements.txt /workspace/
#COPY wait-for.sh /workspace/
RUN pip3 install -r requirements.txt
#RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Clean up
RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*